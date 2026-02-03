# frozen_string_literal: true

class PagesController < Abstract::FrontendController
  require_permission 'helpdesk.page.store'

  def edit
    @page = Page.find_or_initialize_by(
      name: params[:id],
      locale: params.require(:locale)
    )
  end

  def update
    @page = Page.find_or_initialize_by(
      name: params[:id],
      locale: params.require(:locale)
    )

    processor = process_uploads(@page)

    @page.assign_attributes(page_params.except(:text))
    @page.text = processor.result

    if processor.valid? && @page.save
      processor.commit!
      processor.obsolete_uris.each do |uri|
        # The page has been saved, so obsolete S3 files can be removed now.
        # Fault-tolerance: Wait one minute to allow pages for users with slow
        # connection to finish loading.
        S3FileDeletionJob.set(wait: 1.minute).perform_later(uri)
      end

      redirect_to page_path(@page.name)
    else
      processor.rollback!
      processor.errors.each do |_url, code, _message|
        @page.errors.add :text, code
      end

      render 'edit', status: :unprocessable_entity
    end
  end

  private

  def page_params
    params.require(:page).permit(:title, :text)
  end

  def locale_param
    # Don't try to detect the user's new language from the query string.
    # We are using this parameter here to determine which language to edit.
    nil
  end

  def process_uploads(page)
    processor = Xikolo::S3::TextWithUploadsProcessor.new \
      bucket: :pages,
      purpose: 'helpdesk_page_file',
      current: page.text,
      text: page_params[:text],
      check_override: false,
      valid_refs: Xikolo::S3.extract_file_refs(
        page.other_translations.pluck(:text).join("\n")
      )
    processor.on_new do |upload|
      id = UUID4.new.to_s(format: :base62)
      {
        key: "pages/#{page.name}/#{id}/#{File.basename upload.key}",
        acl: 'public-read',
        cache_control: 'public, max-age=7776000',
        content_disposition: 'inline',
        content_type: upload.content_type,
      }
    end
    processor.parse!
    processor
  end
end

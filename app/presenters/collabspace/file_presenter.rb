# frozen_string_literal: true

module Collabspace
  class FilePresenter
    include ActionView::Helpers::NumberHelper
    include ActionView::Helpers::AssetTagHelper
    include Rails.application.routes.url_helpers

    def initialize(file, current_user, collabspace)
      @file = file
      @current_user = current_user
      @collabspace = collabspace
    end

    def icon
      case file_extension
        when 'pdf'
          'file-pdf'
        when 'txt'
          'file-lines'
        when 'jpg', 'png', 'gif'
          'file-image'
        when 'docx', 'odt'
          'file-word'
        when 'xlsx', 'ods'
          'file-excel'
        else
          'paperclip'
      end
    end

    def id
      @file['id']
    end

    def title
      @file['title']
    end

    def modified_at
      Time.zone.parse(@file['created_at']).strftime I18n.t(:'time.formats.short')
    end

    def editor_name
      editor['display_name']
    end

    def editor_id
      editor['id']
    end

    def size
      number_to_human_size(@file['size'])
    end

    def download_url
      @file['blob_url']
    end

    def can_delete?
      return true if @file['creator_id'] == @current_user.id
      return true if @current_user.allowed?('collabspace.file.manage')
      return true if privileged?

      false
    end

    private

    def editor
      @editor ||= Xikolo.api(:account).value!
        .rel(:user).get(id: @file['creator_id']).value!
    end

    def file_extension
      @file_extension ||= ::File.extname(@file['original_filename'])[1..]
    end

    def privileged?
      !membership.nil? &&
        (membership['status'] == 'admin' || membership['status'] == 'mentor')
    end

    def membership
      @membership ||= Xikolo.api(:collabspace).value!
        .rel(:memberships)
        .get(collab_space_id: @collabspace['id'], user_id: @current_user.id)
        .value!.first
    end
  end
end

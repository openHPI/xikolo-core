# frozen_string_literal: true

module NewsService
class NewsController < ApplicationController # rubocop:disable Layout/IndentationWidth
  module APIBehaviorFix
    def api_behavior
      if put? || patch?
        display resource, status: :ok
      else
        super
      end
    end
  end

  responders APIBehaviorFix,
    Responders::DecorateResponder,
    Responders::HttpCacheResponder,
    Responders::PaginateResponder

  respond_to :json

  def index
    news = News.includes(:translations).all

    if params['user_id']
      decoration_context[:read_state] = true
      news = news.with_read_states_for(params[:user_id])

      news = if params['global'].present?
               news.for_groups(user: params['user_id'])
                 .or(news.where(course_id: course_ids_for(params[:user_id])))
             else
               news.where(course_id: course_ids_for(params[:user_id]))
             end
    elsif params['global'].present?
      news = news.for_groups(user: nil)
    end

    news.where! 'course_id IS NOT NULL' if params['all_courses'] == 'true'

    news.where! course_id: params['course_id'] if params['course_id']

    if params[:global_read_count]
      include_global_read_count
      news.includes(:read_state)
    end
    if params['only_homepage']
      news.where! show_on_homepage: params['only_homepage']
    end
    if params['published'] == 'true'
      news.where!('publish_at < ?', Time.zone.now.to_s)
    end
    news.order!(publish_at: :desc)

    respond_with news
  end

  # The actions below are meant for managing global announcements (deprecated)
  def show
    respond_with News.find params[:id]
  end

  def create
    announcement = News.new announcement_params
    richtexts = []

    news_translations = all_translations.map do |locale, translation|
      richtext = process_news_richtext(translation['text'])
      richtext.parse! if richtext.valid?
      richtexts << richtext

      NewsTranslation.new(
        locale:,
        title: translation['title'],
        text: richtext.result
      )
    end

    announcement.translations = news_translations

    if richtexts.all?(&:valid?)
      announcement.save!
      richtexts.each(&:commit!)
    else
      richtexts.each do |richtext|
        richtext.rollback!
        richtext.errors.each do |_url, _code, message|
          announcement.errors.add(:base, message)
        end
      end
    end

    respond_with announcement
  end

  def update
    announcement = News.find UUID4(params[:id]).to_s

    announcement.assign_attributes announcement_params
    if translations?
      richtexts = []

      existing_translations_hash = announcement.translations
        .index_by(&:locale)

      processed_translations = all_translations.map do |locale, translation|
        old_translation = existing_translations_hash[locale]
        richtext = process_news_richtext(
          translation['text'],
          current_text: old_translation&.text,
          valid_refs: old_translation ? Xikolo::S3.extract_file_refs(old_translation.text) : []
        )
        richtext.parse! if richtext.valid?
        richtexts << richtext

        NewsTranslation.new(
          locale:,
          title: translation['title'],
          text: richtext.result
        )
      end

      announcement.translations = processed_translations

      if richtexts.all?(&:valid?)
        announcement.save!
        richtexts.each(&:commit!)
      else
        richtexts.each do |richtext|
          richtext.rollback!
          richtext.errors.each do |_url, _code, message|
            announcement.errors.add(:base, message)
          end
        end
      end
    else
      announcement.save!
    end

    respond_with announcement
  end

  def destroy
    announcement = News.find UUID4(params[:id]).to_s

    respond_with announcement.destroy
  end

  def decoration_context
    @decoration_context ||= params.permit(:embed, :language)
  end

  private

  def process_news_richtext(text, current_text: nil, valid_refs: [])
    richtext = Xikolo::S3::TextWithUploadsProcessor.new(
      bucket: :news,
      purpose: 'news_text_image',
      text:,
      current: current_text,
      valid_refs: valid_refs
    )
    richtext.on_new do |upload|
      nid = UUID4.new.to_str(format: :base62)
      {
        key: "news/#{nid}_#{File.basename(upload.key)}",
        acl: 'public-read',
        cache_control: 'public, max-age=7776000',
        content_disposition: 'inline',
        content_type: upload.content_type,
      }
    end
    richtext
  end

  def course_ids_for(user_id)
    Xikolo.api(:course).value!
      .rel(:enrollments).get({user_id:}).value!
      .pluck('course_id')
  end

  def include_global_read_count
    decoration_context[:global_read_count] = true
  end

  def announcement_params
    params.permit :course_id, :author_id, :publish_at, :state,
      :show_on_homepage, :receivers, :audience
  end

  def all_translations
    @all_translations ||= {}.tap do |translations|
      if params[:translations].respond_to?(:to_hash)
        translations.merge!(params[:translations]
                              .to_unsafe_h
                              .select {|_, v| v.respond_to?(:to_hash) })
      end

      if params.key?('title') && params.key?('text')
        translations['en'] = params.slice('title', 'text')
      end
    end
  end

  def translations?
    !all_translations.empty?
  end
end
end

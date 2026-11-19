# frozen_string_literal: true

class Admin::NewsForm < XUI::Form
  self.form_name = 'announcement'

  class Translation < XUI::Form
    self.form_name = 'translation'

    attribute :title, :single_line_string
    attribute :text, :markup,
      uploads: {
        purpose: 'news_text_image',
        content_type: 'image/*',
      }

    attribute :language, :single_line_string

    def self.readonly_attributes
      %w[language]
    end
  end

  attribute :id, :uuid
  attribute :title, :single_line_string
  attribute :show_on_homepage, :boolean, default: true
  attribute :publish_at, :datetime
  attribute :text, :markup,
    uploads: {
      purpose: 'news_text_image',
      content_type: 'image/*',
    }
  attribute :language, :single_line_string
  attribute :audience, :single_line_string

  attribute :translations,
    :list,
    subtype: :subform,
    subtype_opts: {klass: Translation},
    default: []

  validates :title, :publish_at, :text, presence: true
  validate :title_and_text?

  def self.readonly_attributes
    %w[language]
  end

  class TranslationsArray
    def to_resource(resource, _obj)
      resource['translations'] = resource['translations'].to_h do |t|
        # Avoid pushing empty translations to the news service. The
        # #title_and_text? validation prevents empty translations frontend-wise.
        [t['language'], (t.except('language') if t['title'].present?)]
      end.compact
      resource
    end

    def from_resource(resource, _obj)
      resource['translations'] = resource['translations']
        .each_pair
        .map {|l, t| t.merge('language' => l) }
      resource
    end
  end

  process_with { TranslationsArray.new }

  def visual_url?
    visual_url.present?
  end

  def all_translations
    translation_languages.map do |language|
      translations
        .find {|t| t.language == language } || Translation.new('language' => language)
    end
  end

  def audience_collection
    Xikolo.config.access_groups.map do |group_name, readable_name|
      [readable_name, group_name]
    end
  end

  def audience?
    Xikolo.config.access_groups.present? || audience.present?
  end

  private

  def translation_languages
    Xikolo.config.locales['available'] - [language]
  end

  def title_and_text?
    translations.each do |translation|
      markup = translation.text['markup'] if translation.text.is_a?(Hash)
      next if translation.title.present? && markup.present?
      next if translation.title.blank? && (translation.text.blank? || markup.blank?)

      errors.add :base,
        I18n.t(:'.errors.messages.announcement.base.translation_title_text')
    end
  end
end

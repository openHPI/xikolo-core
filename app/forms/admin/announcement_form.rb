# frozen_string_literal: true

class Admin::AnnouncementForm < XUI::Form
  self.form_name = 'announcement'

  class Translation < XUI::Form
    self.form_name = 'translation'

    attribute :subject, :single_line_string
    attribute :content, :markup
    attribute :language, :single_line_string

    def self.readonly_attributes
      %w[language]
    end
  end

  attribute :id, :uuid
  attribute :subject, :single_line_string
  attribute :content, :markup
  attribute :language, :single_line_string

  attribute :translations,
    :list,
    subtype: :subform,
    subtype_opts: {klass: Translation},
    default: []

  validates :subject, :content, presence: true
  validate :subject_and_content?

  def self.readonly_attributes
    %w[language]
  end

  class TranslationsArray
    def to_resource(resource, _obj)
      other_translations = resource['translations'].to_h do |t|
        [t['language'], (t.except('language') if t['subject'].present?)]
      end.compact

      resource['translations'] = {
        resource.delete('language') => {
          subject: resource.delete('subject'),
          content: resource.delete('content'),
        },
        **other_translations,
      }

      resource
    end

    def from_resource(resource, _obj)
      language = Xikolo.config.locales['default']
      resource['subject'] = resource['translations'][language]['subject']
      resource['content'] = resource['translations'][language]['content']
      resource['translations'] = resource['translations'].except(language)
        .each_pair
        .map {|l, t| t.merge('language' => l) }
      resource['language'] = language
      resource
    end
  end

  process_with { TranslationsArray.new }

  def all_translations
    translation_languages.map do |language|
      translations
        .find {|t| t.language == language } || Translation.new('language' => language)
    end
  end

  private

  def translation_languages
    Xikolo.config.locales['available'] - [language]
  end

  def subject_and_content?
    translations.each do |translation|
      next if translation.subject.present? && translation.content.present?
      next if translation.subject.blank? && translation.content.blank?

      errors.add :base,
        I18n.t(:'.errors.messages.announcement.base.translation_title_text')
    end
  end
end

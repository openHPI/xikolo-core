# frozen_string_literal: true

class Admin::AnnouncementEmailForm < XUI::Form
  self.form_name = 'announcement_email'

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
  attribute :recipients, :list, subtype: :single_line_string, default: []
  attribute :consents, :list, subtype: :single_line_string, default: []
  attribute :language, :single_line_string
  attribute :test, :boolean, default: false

  attribute :translations,
    :list,
    subtype: :subform,
    subtype_opts: {klass: Translation},
    default: []

  validates :subject, :content, :recipients, presence: true
  validate :subject_and_content?
  validate :valid_recipients

  def self.readonly_attributes
    %w[language]
  end

  class RecipientsArray
    def to_resource(resource, _obj)
      resource['recipients'] = resource['recipients'].filter_map do |recipient|
        case recipient
          when /^user:(.+)/
            "urn:x-xikolo:account:user:#{Regexp.last_match(1)}"
          when /^group:(.+)/
            "urn:x-xikolo:account:group:#{Regexp.last_match(1)}"
        end
      end

      resource
    end

    def from_resource(resource, _obj)
      resource['recipients'] = resource['recipients'].filter_map do |recipient|
        if recipient.match(/^urn:x-xikolo:account:(.+)/).present?
          next Regexp.last_match(1)
        end
      end

      resource
    end
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

  process_with { RecipientsArray.new }
  process_with { TranslationsArray.new }

  def all_translations
    translation_languages.map do |language|
      translations
        .find {|t| t.language == language } || Translation.new('language' => language)
    end
  end

  def recipients_collection
    recipients.map do |recipient|
      case recipient
        when /^user:(.+)/
          user = account_service.rel(:user).get(id: Regexp.last_match(1)).value!
          ["#{user['name']} (#{user['email']})", recipient]
        when /^group:course.([\w-]+).students/
          title = Course::Course.find_by(course_code: Regexp.last_match(1))&.title
          [I18n.t('admin.announcement_email.recipients_course_students', course: title,
            course_code: Regexp.last_match(1)), recipient]
        when /^group:(.+)/
          group = account_service.rel(:group).get(id: Regexp.last_match(1)).value!
          [group['description'], recipient]
      end
    end
  end

  def consents_collection
    treatments.map do |treatment|
      label = I18n.t(:"account.shared.consent.#{treatment['name']}.label")
      # Use the corresponding treatment group name as value to
      # be persisted in xi-news.
      [label, "treatment.#{treatment['name']}"]
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

  def valid_recipients
    return if recipients.all? {|r| r.match?(/^(user|group):(.+)/) }

    errors.add :recipients,
      I18n.t(:'.errors.messages.announcement_email.recipients.invalid')
  end

  def treatments
    account_service.rel(:treatments).get.value!
  end

  def account_service
    @account_service ||= Xikolo.api(:account).value!
  end
end

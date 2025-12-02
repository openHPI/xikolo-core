# frozen_string_literal: true

class Admin::ChannelForm < XUI::Form
  extend ChannelHelper

  self.form_name = 'channel'

  # Build a form from a channel record (used by from_resource)
  def self.from_resource(channel)
    form = super

    translations = channel['title_translations'] || {}

    form.title_en = translations['en']
    form.title_de = translations['de']

    form
  end

  attribute :id, :uuid
  attribute :code, :single_line_string
  attribute :name, :single_line_string
  attribute :title_en, :string
  attribute :title_de, :string
  attribute :stage_statement, :markup
  attribute :public, :boolean
  attribute :logo_upload_id, :upload,
    purpose: :course_channel_logo
  attribute :mobile_visual_upload_id, :upload,
    purpose: :course_channel_mobile_visual,
    image_width: mobile_min_width,
    image_height: mobile_min_height
  attribute :stage_visual_upload_id, :upload,
    purpose: :course_channel_stage_visual,
    image_width: stage_min_width,
    image_height: stage_min_height

  localized_attribute :description, :markup

  localized_attribute :info_link_url, :uri
  localized_attribute :info_link_label, :single_line_string

  validates :code, presence: true
  validates :name, presence: true
  validate :valid_info_links

  def to_param
    code
  end

  process_with { InfoLinkHash.new }

  class InfoLinkHash
    def to_resource(resource, _obj)
      resource['info_link'] = {
        'href' => resource['info_link_url'],
        'label' => resource['info_link_label'].to_h do |language, label|
          # Avoid saving URLs without a proper label.
          [language, (label if resource['info_link_url'][language].present?)]
        end.compact,
      }
      resource['title_translations'] = {'de' => resource['title_de'], 'en' => resource['title_en']}

      resource.except('info_link_url', 'info_link_label')
    end

    def from_resource(resource, _obj)
      resource['info_link_url'] = resource.dig('info_link', 'href')
      resource['info_link_label'] = resource.dig('info_link', 'label')
      resource.except('info_link')
    end
  end

  def valid_info_links
    # Ensure all given info link URLs have a corresponding label
    info_link_url.each_key do |l|
      if info_link_label[l].blank?
        errors.add :"info_link_label_#{l}",
          I18n.t(:'.errors.messages.channel.info_link_label.required')
      end
    end
  end
end

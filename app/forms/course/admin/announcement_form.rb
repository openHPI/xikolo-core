# frozen_string_literal: true

class Course::Admin::AnnouncementForm < XUI::Form
  self.form_name = 'announcement'

  attribute :title, :single_line_string
  attribute :publish_at, :datetime
  attribute :text, :markup

  validates :title, :publish_at, :text, presence: true
end

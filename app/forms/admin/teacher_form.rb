# frozen_string_literal: true

class Admin::TeacherForm < XUI::Form
  self.form_name = 'teacher'

  attribute :name, :single_line_string
  attribute :picture, :new_upload,
    purpose: :course_teacher_picture
  attribute :delete_picture, :boolean

  localized_attribute :description, :markup

  validates :name, presence: true
  validates :delete_picture, inclusion: [true, nil]
end

# frozen_string_literal: true

module CourseService
class DocumentLocalization < ApplicationRecord # rubocop:disable Layout/IndentationWidth
  self.table_name = :document_localizations

  include FileReference

  has_paper_trail

  validates :title, presence: true
  validates :description, presence: true
  validates :language, presence: true

  belongs_to :document

  file_reference :file, lambda {|doc, rev, upload|
    did = UUID4(doc.document_id).to_str(format: :base62)
    {
      key: "documents/#{did}/#{doc.language}_v#{rev}.pdf",
      acl: 'public-read',
      cache_control: 'public, max-age=7776000',
      content_disposition: "attachment; filename=\"#{upload.sanitized_name}\"",
      content_type: 'application/pdf',
    }
  }, required: true, purpose: :course_document

  scope :not_deleted, -> { where(deleted: false) }

  after_create do
    Msgr.publish(decorate.as_event, to: 'xikolo.course.document_localization.create')
  end

  after_update do
    Msgr.publish(decorate.as_event, to: 'xikolo.course.document_localization.update')
  end

  def soft_delete
    update! deleted: true
    Msgr.publish(decorate.as_event, to: 'xikolo.course.document_localization.destroy')
    self
  end
end
end

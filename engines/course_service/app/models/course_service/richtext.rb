# frozen_string_literal: true

module CourseService
class Richtext < ApplicationRecord # rubocop:disable Layout/IndentationWidth
  self.table_name = :richtexts

  belongs_to :course
  has_one :item,
    class_name: 'CourseService::Item',
    as: :content,
    dependent: :restrict_with_exception

  after_commit :delete_s3_objects!, on: :destroy

  attribute :text, Xikolo::S3::Markup.new(
    uploads: {purpose: 'course_richtext', content_type: ['image/*', 'application/pdf']}
  )

  validates :text, presence: true

  def self.polymorphic_name
    'rich_text'
  end

  def self.referenced?(uri)
    exists?(reading_material_uri: uri) ||
      Course.exists?(['description LIKE ?', "%#{uri}%"]) ||
      exists?(['text LIKE ?', "%#{uri}%"])
  end

  def reading_material_url
    Xikolo::S3.object(reading_material_uri).public_url if reading_material_uri
  end

  private

  def delete_s3_objects!
    uris = [reading_material_uri]
    uris += Xikolo::S3.extract_file_refs(text)
    uris.compact.each do |uri|
      S3FileDeletionJob.set(wait: 1.hour).perform_later(uri) unless self.class.referenced?(uri)
    end
  end
end
end

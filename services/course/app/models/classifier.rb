# frozen_string_literal: true

class Classifier < ApplicationRecord
  has_and_belongs_to_many :courses
  belongs_to :cluster

  validates :title,
    presence: true,
    format: {with: /\A[\w\-\ ]+\z/, message: 'invalid_format'},
    uniqueness: {scope: :cluster_id, case_sensitive: false, message: 'not_unique'}
  validate do
    if translations[Xikolo.config.locales['default']].blank?
      errors.add :translations, :missing
    end
  end

  after_commit :update_course_search_index, on: :update
  around_destroy :update_course_search_index

  private

  def update_course_search_index
    course_ids = courses.pluck(:id)
    yield if block_given?

    job_args = course_ids.map {|x| [x] }
    UpdateCourseSearchIndexWorker.perform_bulk(job_args)
  end
end

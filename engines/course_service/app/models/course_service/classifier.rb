# frozen_string_literal: true

module CourseService
class Classifier < ApplicationRecord # rubocop:disable Layout/IndentationWidth
  self.table_name = :classifiers

  has_many :classifier_assignments
  has_many :courses, lambda {
                       not_deleted.order('classifiers_courses.position')
                     }, through: :classifier_assignments
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

  acts_as_list scope: :cluster

  scope :query, ->(query) { where('title ILIKE ?', "%#{sanitize_sql_like(query)}%") }

  class << self
    def order_for(cluster)
      scope = merge(where(cluster_id: cluster.id))
      if cluster.sort_mode == 'manual'
        scope.order(:position)
      else
        scope.order(
          Arel.sql(<<~SQL.squish)
            COALESCE(
              translations->>'#{I18n.locale}',
              translations->>'#{Xikolo.config.locales['default']}',
              title
            ) ASC NULLS LAST
          SQL
        )
      end
    end
  end

  def localized_title
    Translations.new(translations).to_s.presence || title.titleize
  end

  around_destroy :update_course_search_index
  after_commit :update_course_search_index, on: :update

  private

  def update_course_search_index
    course_ids = courses.pluck(:id)
    yield if block_given?

    job_args = course_ids.zip
    job_args.each do |course_id|
      UpdateCourseSearchIndexJob.perform_later(course_id)
    end
  end
end
end

# frozen_string_literal: true

module CourseService
class Cluster < ApplicationRecord # rubocop:disable Layout/IndentationWidth
  CLASSIFIER_LIMIT = 5

  self.table_name = :clusters

  has_many :classifiers, ->(cluster) { order_for(cluster) },
    inverse_of: :cluster,
    dependent: :delete_all
  scope :visible, -> { where(visible: true) }

  validates :id,
    presence: true,
    format: {with: /\A[\w-]+\z/, message: :invalid_format},
    uniqueness: {case_sensitive: false, message: :not_unique}
  validates :sort_mode,
    presence: true,
    inclusion: %w[automatic manual]
  validate do
    if translations[Xikolo.config.locales['default']].blank?
      errors.add :translations, :missing
    end
  end

  def title
    Translations.new(translations).to_s.presence || id.titleize
  end

  def classifiers_preview
    titles = classifiers.limit(CLASSIFIER_LIMIT).map(&:title).join(', ')
    other_count = [0, classifiers.count - CLASSIFIER_LIMIT].max
    I18n.t(:'admin.clusters.classifiers_preview', count: other_count, classifiers: titles)
  end
end
end

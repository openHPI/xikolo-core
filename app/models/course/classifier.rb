# frozen_string_literal: true

module Course
  class Classifier < ::ApplicationRecord
    has_many :classifier_assignments, class_name: '::Course::ClassifierAssignment', dependent: :delete_all
    has_many :courses, lambda {
                         not_deleted.order('classifiers_courses.position')
                       }, through: :classifier_assignments
    belongs_to :cluster, class_name: '::Course::Cluster'
    acts_as_list scope: :cluster

    validates :title,
      presence: true,
      format: {with: /\A[\w\-\ ]+\z/, message: :invalid_format},
      uniqueness: {scope: :cluster_id, case_sensitive: false, message: :not_unique}
    validate do
      if translations[Xikolo.config.locales['default']].blank?
        errors.add :translations, :missing
      end
    end

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

    ## ROUTE HELPERS
    ## Ensure that Rails routing helpers can be used directly with Classifier instances.

    def self.model_name
      ActiveModel::Name.new(self, nil, 'Classifier')
    end

    def to_param
      id
    end

    def localized_title
      Translations.new(translations).to_s.presence || title.titleize
    end
  end
end

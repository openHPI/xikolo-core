# frozen_string_literal: true

module Course
  class Cluster < ::ApplicationRecord
    has_many :classifiers, ->(cluster) { order_for(cluster) },
      inverse_of: :cluster,
      dependent: :delete_all

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

    class << self
      def visible
        where(visible: true)
      end
    end

    ## ROUTE HELPERS
    ## Ensure that Rails routing helpers can be used directly with Cluster instances.

    def self.model_name
      ActiveModel::Name.new(self, nil, 'Cluster')
    end

    def to_param
      id
    end

    CLASSIFIER_LIMIT = 5
    def classifiers_preview
      titles = classifiers.limit(CLASSIFIER_LIMIT).map(&:title).join(', ')
      other_count = [0, classifiers.count - CLASSIFIER_LIMIT].max
      I18n.t(:'admin.clusters.classifiers_preview', count: other_count, classifiers: titles)
    end

    def title
      Translations.new(translations).to_s.presence || id.titleize
    end
  end
end

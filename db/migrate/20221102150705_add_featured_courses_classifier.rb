# frozen_string_literal: true

class AddFeaturedCoursesClassifier < ActiveRecord::Migration[6.0]
  module Course
    class Course < ActiveRecord::Base; end

    class Cluster < ActiveRecord::Base
      has_many :classifiers,
        inverse_of: :cluster,
        dependent: :delete_all
    end

    class Classifier < ActiveRecord::Base
      has_and_belongs_to_many :courses
      belongs_to :cluster
    end
  end

  def change
    reversible do |dir|
      dir.up do
        cluster = Course::Cluster
          .create_with(translations: {en: 'Course List', de: 'Kursliste'}, visible: false)
          .find_or_create_by!(id: 'course-list')
        Course::Classifier.create! cluster:, title: 'Featured'
      end
      dir.down do
        Course::Cluster.find('course-list')&.destroy
      end
    end
  end
end

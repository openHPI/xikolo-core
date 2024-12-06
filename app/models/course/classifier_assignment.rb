# frozen_string_literal: true

module Course
  class ClassifierAssignment < ::ApplicationRecord
    self.table_name = 'classifiers_courses'

    belongs_to :classifier, class_name: '::Course::Classifier'
    belongs_to :course, class_name: '::Course::Course'
  end
end

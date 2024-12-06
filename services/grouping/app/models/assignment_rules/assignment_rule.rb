# frozen_string_literal: true

module AssignmentRules
  class AssignmentRule < ::ApplicationRecord
    # Map "type" column values to concrete subclasses.
    # NOTE: This can be used to map obsolete values to newer classes, or when
    # renaming models.
    STI_TYPE_TO_CLASS = {
      'RandomAssignmentRule' => '::AssignmentRules::RandomAssignmentRule',
      'RoundRobinAssignmentRule' => '::AssignmentRules::RoundRobinAssignmentRule',
    }.freeze

    # What "type" should be used when storing each subclass?
    STI_CLASS_TO_TYPE = {
      'AssignmentRules::RandomAssignmentRule' => 'RandomAssignmentRule',
      'AssignmentRules::RoundRobinAssignmentRule' => 'RoundRobinAssignmentRule',
    }.freeze

    belongs_to :user_test

    class << self
      ##
      # Resolve the concrete subclass to use for a value of the type column.
      #
      # This overrides ActiveRecord::Inheritance::ClassMethods#find_sti_class.
      def find_sti_class(type_name)
        if (cls = STI_TYPE_TO_CLASS[type_name])
          ::ActiveSupport::Dependencies.constantize(cls)
        else
          raise SubclassNotFound.new("Unsupported record type: #{type_name}")
        end
      end

      ##
      # Determine the type identifier to use as "type" when storing a concrete subclass.
      #
      # This overrides ActiveRecord::Inheritance::ClassMethods#sti_name.
      def sti_name
        STI_CLASS_TO_TYPE.fetch(name)
      end
    end

    ## ROUTE HELPERS
    ## Ensure that Rails routing helpers can be used directly with AssignmentRule instances.

    def self.model_name
      ActiveModel::Name.new(self, nil, 'AssignmentRule')
    end

    def to_param
      id
    end

    def assign(*_args)
      0
    end
  end
end

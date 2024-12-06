# frozen_string_literal: true

module XUI
  class Form
    #
    # Customize form name
    #
    module Naming
      attr_accessor :form_name

      def model_name
        if form_name
          ActiveModel::Name.new(self, nil, form_name)
        else
          super
        end
      end

      def human_name
        if form_name
          ::ActiveModel::Name.new(self, nil, form_name)
        else
          super
        end
      end
    end
  end
end

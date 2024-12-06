# frozen_string_literal: true

module RestifyForwardable
  # a `def_delegators` compatible method designed to be used on restify
  # responses: the field are access via obj['field_name'] not obj.field_name.
  # the references object can be a `Restify::Promise`, the promise will be
  # resolved transparently on access.
  def def_restify_delegators(dest, *fields)
    fields.each do |field|
      class_eval <<-RUBY_EVAL, __FILE__, __LINE__ + 1
        # delegates to restify resource or promise:
        # restify strict modus compatible
        def #{field}                                              # def name
          value = #{dest}                                         #   value = @promise
          value = value.value! if value.is_a?(Restify::Promise)   #   value = value.value! if value.is_a?(Restify::Promise)
          value[#{field.to_s.inspect}]                            #   value['name']
        end                                                       # end
      RUBY_EVAL
    end
  end
end

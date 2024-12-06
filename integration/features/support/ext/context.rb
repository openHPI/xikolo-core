# frozen_string_literal: true

class Context
  class ContextError < StandardError; end

  # Invoke given block with given context variables.
  #
  # If a variables is nil a ContextError will be raised.
  #
  # @example
  #   context.with(:user, :course) do |user, course|
  #     # ...
  #   end
  #
  def with(*names)
    yield(*get(names))
  end

  # Return list of given context variables or single
  # context object if only one argument is given.
  #
  # If a variables is nil a ContextError will be raised.
  #
  # @example
  #   user, course = context.fetch :user, :course
  #
  # @example
  #   user = context.fetch :user
  #
  def fetch(*names)
    objects = get(names)
    names.size <= 1 ? objects.first : objects
  end

  # Assign given object to named context variable.
  #
  # If a context variable with given name already assigned
  # an error will be raised unless :force option is set to
  # a true value.
  #
  # @example
  #   context.assign :user, "User"
  #   # => "User"
  #
  #   context.assign :user, "Another User"
  #   # => ContextError
  #
  #   context.assign :user, "Another User", force: true
  #   # => "Another User"
  #
  def assign(name, object, force: false, allow_nil: false)
    if !allow_nil && object.nil?
      raise ContextError.new \
        "Assigned object for `#{name}` is nil! If you really want to assign nil, set allow_nil: true."
    end

    if storage.key?(name) && !force
      raise ContextError.new "Context variable #{name} is already assigned."
    else
      storage[name] = object
    end
  end

  # Clear the context storage.
  #
  # This prevents leaking context into following scenarios.
  #
  def reset!
    storage.clear
  end

  private

  def storage
    @storage ||= {}
  end

  def get(names)
    missing = []
    objects = names.map {|n| storage.fetch(n) { missing << n } }
    unless missing.empty?
      raise ContextError.new 'Missing context variables: ' \
                             "#{missing.map(&:inspect).join(', ')}"
    end
    objects
  end

  module World
    def context
      @context ||= Context.new
    end
  end
end

Gurke.configure do |config|
  config.include Context::World

  config.before(:scenario) do
    context.reset!
  end
end

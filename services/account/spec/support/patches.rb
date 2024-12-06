# frozen_string_literal: true

class Array
  def symbolize_keys
    map {|el| el.respond_to?(:symbolize_keys) ? el.symbolize_keys : el }
  end

  def to_struct
    map(&:to_struct)
  end
end

class Object
  def to_struct
    self
  end
end

class Hash
  def to_struct
    cls = Struct.new(*keys.map(&:to_sym)) do
      def include?(arg)
        if arg.is_a?(Hash)
          arg.reject {|k, v| respond_to?(k) && send(k) == v }.empty?
        else
          super
        end
      end
    end
    cls.new(*values.to_struct)
  end
end

# frozen_string_literal: true

class ApplicationDecorator < Draper::Decorator
  def export(*fields, **opts)
    export = extract fields.flatten
    export.as_json opts
  end

  def to_msgpack(opts)
    as_json(opts).to_msgpack
  end

  private

  def extract(fields)
    fields.each_with_object({}) do |field, hash|
      case field
        when Symbol, String
          hash[field] = send field
        when Hash
          field.each_pair {|name, mth| hash[name] = send mth }
      end
    end
  end
end

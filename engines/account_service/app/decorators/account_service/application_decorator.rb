# frozen_string_literal: true

module AccountService
class ApplicationDecorator < Draper::Decorator # rubocop:disable Layout/IndentationWidth
  # Draper will use the main apps helper by default.
  def h
    super.account_service
  end

  def export(*fields, **opts)
    export = extract fields.flatten
    export.as_json opts
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
end

# frozen_string_literal: true

module PointsProcessor
  def parse_points(name)
    return nil if params[name].nil?

    input = params[name].to_f * 10
    input = input.to_i if (input % 1.0).zero?
    input
  end

  def fix_errors(obj, internal, external)
    # do not expose dpoints -> only points
    return unless obj.errors.include? internal

    obj.errors.delete(internal).each do |error|
      obj.errors.add external, error
    end
  end
end

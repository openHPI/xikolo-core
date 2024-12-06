# frozen_string_literal: true

module FeatureTogglesHelper
  def feature?(name, *values)
    return false unless current_user.feature_set? name

    # When we don't ask for any specific value, the feature existing is enough
    return true if values.empty?

    # Cycle through the given possible values and see if they match
    feature_value = current_user.feature name
    values.any? {|value| feature_value == value.to_s }
  end
end

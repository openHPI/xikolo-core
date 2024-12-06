# frozen_string_literal: true

# Since distribution does not support a non-centrality parameter for the
# t distribution, this is a tabulated approach
module SampleSizeHelper
  def sample_size(effect_size, type)
    case type.to_sym
      when :normal then sizes = SAMPLE_SIZES['d']
      when :binomial then sizes = SAMPLE_SIZES['h']
      else
        raise ArgumentError.new "Unknown distribution: #{type}"
    end

    effect_size = sizes.keys.max if effect_size > sizes.keys.max
    sizes[(effect_size - 0.005).round 2] # get nearest stored value
  end

  SAMPLE_SIZES = YAML.safe_load(
    Rails.root.join('config/sample_sizes.yml').read
  )
end

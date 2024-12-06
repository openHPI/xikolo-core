# frozen_string_literal: true

# rubocop:disable Naming/MethodParameterName
# ^ Coordinates typically have one-letter names, this is fine here.
module TestHelper
  # based on https://github.com/davejacobs/stats/blob/master/lib/stats/significance.rb
  # Welch Two Sample t-test
  def two_sample_t(x, y, tail: :right)
    nx = x.length
    ny = y.length

    df = (((variance(x, :sample) / nx) + (variance(y, :sample) / ny))**2) /
         ((((variance(x, :sample) / nx)**2) / (nx - 1)) +
             (((variance(y, :sample) / ny)**2) / (ny - 1)))

    statistic =
      (arithmetic_mean(y) - arithmetic_mean(x)) /
      ::Math.sqrt((variance(x, :sample) / nx) + (variance(y, :sample) / ny))

    if statistic.nan?
      p_value = nil
    else
      p = ::Distribution::T.cdf(statistic, df)
      p_value = calculate_p_value(p, tail)
    end

    {statistic:, p_value:}
  end

  def binomial_test(x, y, tail: :right)
    n = y.size

    p_0 = arithmetic_mean(x)
    p_h = arithmetic_mean(y)

    p_right = nil

    if n * p_0 * (1 - p_0) > 9
      p, statistic = approximate_binomial_test(n, p_0, p_h)
    else
      p, p_right, statistic = exact_binomial_test(n, p_0, p_h)
    end

    p_value = calculate_p_value p, tail, p_right
    {statistic:, p_value:}
  end

  def exact_binomial_test(n, p_0, p_h)
    statistic = p_h * n
    p = ::Distribution::Binomial.cdf(statistic, n, p_0)
    p_right = 1 - ::Distribution::Binomial.cdf(statistic - 1, n, p_0)
    [p, p_right, statistic]
  end

  def approximate_binomial_test(n, p_0, p_h)
    statistic = (p_h - p_0) / ::Math.sqrt(p_0 * (1 - p_0) / n)
    p = ::Distribution::Normal.cdf(statistic)
    [p, statistic]
  end

  def calculate_p_value(p, tail, p_right = nil)
    case tail
      when :both
        2 * [p, p_right || (1 - p)].min
      when :left
        p
      when :right
        p_right || (1 - p)
    end
  end

  def std(values, type = :population)
    return nil if values.empty?

    ::Math.sqrt variance(values, type)
  end

  def arithmetic_mean(values)
    return nil if values.empty?

    values.sum.to_f / values.length
  end

  def variance(values, type = :population)
    return nil if values.empty?

    n = type == :population ? values.length : values.length - 1
    mean = arithmetic_mean(values)
    1.0 / n * values.reduce(0) {|a, e| a + ((e - mean)**2) }
  end

  EFFECT_SIZE_THRESHOLDS = {0.2 => :small, 0.5 => :medium, 0.8 => :large}.freeze

  def effect_size(x, y, type: :normal)
    case type.to_sym
      when :normal then cohens_d(x, y)
      when :binomial then cohens_h(x, y)
      else
        raise ArgumentError.new "Unknown distribution: #{type}"
    end
  end

  def cohens_d(x, y)
    nx = x.length
    ny = y.length
    df = nx + ny - 2

    grand_std = ::Math.sqrt(
      (((nx - 1) * variance(x, :sample)) +
          ((ny - 1) * variance(y, :sample))) / df
    )

    ((arithmetic_mean(y) - arithmetic_mean(x)) / grand_std).abs
  end

  def cohens_h(x, y)
    (2 * (::Math.asin(::Math.sqrt(arithmetic_mean(x))) -
      ::Math.asin(::Math.sqrt(arithmetic_mean(y))))).abs
  rescue Math::DomainError
  end
end
# rubocop:enable all

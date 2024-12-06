# frozen_string_literal: true

class ImgproxyWrapper
  class InvalidParamError < StandardError; end

  def initialize(url, params = {})
    @url = Xikolo.base_url.join(url)
    @params = params
  end

  def proxy_url
    Imgproxy.url_for(
      @url,
      width:,
      height:,
      resizing_type:,
      gravity:,
      enlarge:
    )
  end

  private

  # https://docs.imgproxy.net/#/generating_the_url_basic?id=resizing-types
  def resizing_type
    unless valid?(@params[:resizing_type], %w[fit fill auto])
      raise InvalidParamError.new("Invalid resizing type: #{@params[:resizing_type]}")
    end

    @params[:resizing_type] || 'fit'
  end

  # https://docs.imgproxy.net/#/generating_the_url_basic?id=width-and-height
  def width
    unless valid_dimension?(@params[:width])
      raise InvalidParamError.new("Invalid width: #{@params[:width]}")
    end

    @params[:width] || 0
  end

  # https://docs.imgproxy.net/#/generating_the_url_basic?id=width-and-height
  def height
    unless valid_dimension?(@params[:height])
      raise InvalidParamError.new("Invalid height: #{@params[:height]}")
    end

    @params[:height] || 0
  end

  # https://docs.imgproxy.net/#/generating_the_url_basic?id=gravity
  def gravity
    unless valid?(@params[:gravity], %w[no so ea we noea nowe soea sowe ce sm])
      raise InvalidParamError.new("Invalid gravity: #{@params[:gravity]}")
    end

    @params[:gravity] || 'ce'
  end

  # https://docs.imgproxy.net/#/generating_the_url_basic?id=enlarge
  def enlarge
    unless valid?(@params[:enlarge], [1, 't', true, 0, 'f', false])
      raise InvalidParamError.new("Invalid enlarge: #{@params[:enlarge]}")
    end

    @params[:enlarge] || false
  end

  def valid?(value, supported_values)
    return true if value.nil?

    supported_values.include?(value)
  end

  def valid_dimension?(value)
    return true if value.nil?

    begin
      Integer(value) >= 0 && value % 1 == 0
    rescue
      false
    end
  end
end

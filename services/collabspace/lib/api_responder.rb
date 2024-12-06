# frozen_string_literal: true

class APIResponder < ActionController::Responder
  prepend ::Responders::DecorateResponder
  prepend ::Responders::HttpCacheResponder
  prepend ::Responders::PaginateResponder

  def to_format
    if !get? && has_errors? && !response_overridden?
      display_errors
    elsif response_overridden?
      default_render
    else
      api_behavior
    end
  end

  def api_behavior
    unless has_renderer?
      raise ::ActionController::MissingRenderer.new(format)
    end

    if get?
      display resource
    elsif post?
      display resource, status: :created, location: resource_location
    elsif put? || patch?
      display resource, status: :ok, location: resource_location
    elsif delete?
      display resource, status: :ok
    else
      head :no_content
    end
  end

  def resource_location
    options.fetch(:location) { resources }
  end
end

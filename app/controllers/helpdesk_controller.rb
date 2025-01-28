# frozen_string_literal: true

require 'uri'
require 'xi/recaptcha/integration'

class HelpdeskController < Abstract::FrontendController
  layout :helpdesk_layout

  before_action :set_no_cache_headers

  def send_helpdesk
    @recaptcha = Xi::Recaptcha::Integration.new(request: request, params: params, action: 'helpdesk')
    unless @recaptcha.verified?
      @recaptcha.require_manual_verification!
      @ticket = Helpdesk::TicketForm.new(ticket_params).tap { annotate_with_metadata _1 }

      if helpdesk_layout
        return render action: :show
      else
        return render plain: 'checkbox_recaptcha'
      end
    end

    create_ticket!
    render 'success'
  rescue ActiveRecord::RecordInvalid
    render 'error', status: :unprocessable_entity
  end

  def show
    @recaptcha = Xi::Recaptcha::Integration.new(request: request, params: params, action: 'helpdesk')
    @ticket = Helpdesk::TicketForm.new(ticket_params).tap { annotate_with_metadata _1 }
  end

  private

  def create_ticket!
    params[:mail] = current_user.email if current_user.logged_in?

    # Here you can add as much data as you want...
    data = params[:data].presence || "#{params[:userAgent]}:#{params[:cookie]}:#{params[:language]}"
    user_id = current_user.logged_in? ? current_user.id : ''

    category = params[:category]
    course_id = nil

    if Helpdesk::CategoryOptions.general?(category)
      topic = category
    elsif category.present?
      topic = 'course'
      course_id = category
    else
      topic = Helpdesk::CategoryOptions.default
    end

    Helpdesk::Ticket.create!(
      title: params[:title],
      mail: params[:mail],
      report: params[:report],
      language: I18n.locale,
      course_id:,
      url: referrer_url,
      topic:,
      user_id:,
      data:
    )
  end

  def helpdesk_layout
    request.xhr? ? false : 'simple'
  end

  def annotate_with_metadata(ticket)
    return unless params[:data].respond_to?(:to_unsafe_h)

    ticket.data = params[:data].to_unsafe_h.map {|key, value| "#{key}=#{value}" }.join(':')
  end

  def ticket_params
    params.permit(:title, :mail, :category, :report, :data)
  end

  def referrer_url
    return params[:url] if params[:url]

    return if request.referer.blank?

    URI.parse(request.referer)
  rescue URI::InvalidURIError
    nil # Ignore invalid URLs
  end
end

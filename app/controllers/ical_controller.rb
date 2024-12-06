# frozen_string_literal: true

class IcalController < ApplicationController
  require 'icalendar'
  require 'icalendar/tzinfo'
  require 'digest'

  include Xikolo::Account
  include IcalHelper

  before_action :set_no_cache_headers

  require_feature 'ical_feed'

  def index
    if %i[u h].all? {|k| params[k].present? }
      begin
        uuid = UUID params[:u]
      rescue TypeError
        raise Status::NotFound
      end

      events = Xikolo.api(:course).value!.rel(:next_dates).get(user_id: uuid.to_s).value!

      User.find(uuid.to_s) do |user|
        I18n.locale = user.language if user.language.present?
        if params[:h] == ical_hash(user)
          cal = Icalendar::Calendar.new
          tz = TZInfo::Timezone.get 'UTC'
          cal.add_timezone tz.ical_timezone(Time.zone.now)
          events.each do |next_date|
            cal.event do |e|
              next_date_presenter = Course::NextDatePresenter.new next_date
              if next_date_presenter.id == 'item_submission_deadline'
                e.dtstart = (next_date_presenter.date_obj - 60.minutes).strftime('%Y%m%dT%H%M%SZ')
                e.dtend = next_date_presenter.date_obj.strftime('%Y%m%dT%H%M%SZ')
              else
                e.dtstart = next_date_presenter.date_obj.strftime('%Y%m%dT%H%M%SZ')
                e.dtend = (next_date_presenter.date_obj + 30.minutes).strftime('%Y%m%dT%H%M%SZ')
              end

              e.summary = next_date_presenter.summary
              e.url = next_date_presenter.do_full_url if next_date_presenter.do_full_url.present?
              e.description = next_date_presenter.static_description
              e.ip_class = 'PRIVATE'
              md5 = Digest::MD5.new
              md5.update next_date_presenter.summary.to_s
              e.uid = "#{md5.hexdigest}@#{Xikolo.base_url.host}"
            end
          end
          cal.publish
          render plain: cal.to_ical
        else
          render plain: '', status: :unauthorized
        end
      end
    else
      render plain: 'params missing', status: :unauthorized
    end
    Acfs.run
  end
end

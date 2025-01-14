# frozen_string_literal: true

module Xikolo::Course
  class Course < Acfs::Resource
    service Xikolo::Course::Client, path: 'courses'

    attribute :id, :uuid
    attribute :title, :string
    attribute :course_code, :string
    attribute :context_id, :uuid
    attribute :special_groups, :list
    attribute :abstract, :string
    attribute :url, :string
    attribute :status, :string
    attribute :start_date, :date_time
    attribute :display_start_date, :date_time
    attribute :end_date, :date_time
    attribute :lang, :string
    attribute :classifiers, :dict
    attribute :teacher_ids, :list
    attribute :channel_id, :uuid
    attribute :show_on_stage, :boolean, default: false
    attribute :stage_visual_url, :string
    attribute :stage_statement, :string
    attribute :records_released, :boolean
    attribute :enrollment_delta, :integer
    attribute :teacher_text, :string
    attribute :alternative_teacher_text, :string
    attribute :external_course_url, :string
    attribute :forum_is_locked, :boolean
    attribute :affiliated, :boolean
    attribute :hidden, :boolean
    attribute :welcome_mail, :string
    attribute :created_at, :date_time
    attribute :updated_at, :date_time
    attribute :middle_of_course, :date_time
    attribute :middle_of_course_is_auto, :boolean, default: true
    attribute :proctored, :boolean, default: false
    attribute :auto_archive, :boolean, default: true
    attribute :show_syllabus, :boolean, default: true
    attribute :invite_only, :boolean, default: false
    attribute :on_demand, :boolean, default: true
    attribute :has_collab_space, :boolean, default: true
    attribute :pinboard_enabled, :boolean, default: true
    attribute :policy_url, :dict
    attribute :roa_threshold_percentage, :integer
    attribute :cop_threshold_percentage, :integer
    attribute :roa_enabled, :boolean, default: true
    attribute :cop_enabled, :boolean, default: true
    attribute :video_course_codes, :list
    attribute :rating_stars, :float
    attribute :rating_votes, :integer
    attribute :learning_goals, :list
    attribute :public, :boolean
    attribute :enable_video_download, :boolean
    attribute :external_registration_url, :dict

    def to_param
      course_code
    end

    def sections(&)
      @sections ||= Xikolo::Course::Section.where course_id: id
      Acfs.add_callback(@sections, &)
      @sections
    end

    def published_sections(&)
      @published_sections ||= Xikolo::Course::Section.where course_id: id, published: true
      Acfs.add_callback(@published_sections, &)
      @published_sections
    end

    def published?
      %w[active archive].include?(status)
    end

    def available?(startdate = start_date)
      unlocked?(startdate) && published?
    end

    def was_available?(startdate = start_date)
      published? && (startdate.nil? || startdate < Time.zone.now)
    end

    def fullstate
      startdate = display_start_date.nil? ? start_date : display_start_date
      if status == 'active'
        if available?(startdate)
          'available'
        elsif was_available?(startdate)
          'was_available'
        else
          'upcoming'
        end
      else
        status
      end
    end

    def unlocked?(startdate = start_date)
      if startdate.nil? && end_date.nil?
        true
      elsif startdate.nil?
        end_date > Time.zone.now
      elsif end_date.nil?
        startdate < Time.zone.now
      else
        startdate < Time.zone.now && end_date > Time.zone.now
      end
    end

    def external?
      external_course_url.present?
    end

    def proctored?
      proctored
    end

    def offers_reactivation?
      on_demand
    end

    def statistic(&)
      @statistic ||= Xikolo::Course::Statistic.find course_id: id
      Acfs.add_callback(@statistic, &)
      @statistic
    end

    def roa_enabled?
      roa_enabled
    end

    def cop_enabled?
      cop_enabled
    end
  end
end

# frozen_string_literal: true

module Lti
  class ToolLaunch
    include Rails.application.routes.url_helpers

    def initialize(exercise, user)
      @exercise = exercise
      @user = user
    end

    class << self
      def default_url_options
        {
          protocol: Xikolo.base_url.scheme,
          host: Xikolo.base_url.host,
          port: Xikolo.base_url.port,
        }
      end
    end

    def target_url
      tool_consumer.launch_url
    end

    def form_target
      {
        'pop-up' => '_blank',
        'window' => '_self',
      }[presentation_mode]
    end

    def presentation_mode
      provider.presentation_mode
    end

    def data_hash
      tool_consumer.generate_launch_data
    end

    private

    def tool_consumer
      @tool_consumer ||= provider.tool_consumer.tap do |consumer|
        consumer.set_config(tool_config)

        configure_context consumer
        configure_user consumer

        consumer.launch_presentation_return_url = tool_return_course_item_url(course.course_code, short_item_id)
        if item_open?
          consumer.lis_outcome_service_url = tool_grading_course_item_url(course.course_code, short_item_id)
        end
        consumer.oauth_callback = 'about:blank'
      end
    end

    def configure_context(consumer)
      consumer.context_id = course.id
      consumer.context_title = course.title
      consumer.lis_result_sourcedid = gradebook.id unless @exercise.locked?
      consumer.resource_link_id = @exercise.id
      consumer.resource_link_title = @exercise.title if @exercise.title.present?
    end

    def configure_user(consumer)
      if provider.anonymized?
        anonymized_user_data(consumer)
      elsif provider.pseudonymized?
        pseudonymized_user_data(consumer)
      else
        complete_user_data(consumer)
      end
    end

    def complete_user_data(consumer)
      consumer.lis_person_contact_email_primary = @user.email
      consumer.lis_person_name_family = 'Mous'
      consumer.lis_person_name_given = 'Anony'
      consumer.lis_person_name_full = @user.name
      consumer.user_id = @user.id
      consumer.roles = user_role
    end

    def anonymized_user_data(consumer)
      consumer.roles = user_role
    end

    def pseudonymized_user_data(consumer)
      hashed_user_id = Digest::SHA256.hexdigest("#{provider.id}|#{@user.id}")

      consumer.lis_person_name_full = hashed_user_id
      consumer.user_id = hashed_user_id
      consumer.roles = user_role
    end

    def tool_config
      IMS::LTI::ToolConfig.new(launch_url: provider.domain).tap do |tool_config|
        tool_config.set_custom_param('course', course.course_code)

        @exercise.custom_parameters.each do |key, value|
          tool_config.set_custom_param(key, value)
        end

        tool_config.set_custom_param('state', item_open? ? 'active' : 'expired')
      end
    end

    def provider
      @provider ||= @exercise.provider
    end

    def gradebook
      @gradebook ||= @exercise.gradebooks.find_or_create_by!(user_id: @user.id)
    rescue ActiveRecord::RecordNotUnique
      retry
    end

    def user_role
      if @user.allowed? 'lti.tool.administrate'
        'Administrator'
      elsif @user.allowed? 'lti.tool.instruct'
        'Instructor'
      else
        'Learner'
      end
    end

    def item_open?
      # Important to use actual item with submission deadline set properly
      return true unless item.submission_deadline

      item.submission_deadline_for(@user.id).future?
    end

    def short_item_id
      UUID4(item.id).to_param
    end

    def course
      item.section.course
    end

    def item
      @item ||= @exercise.item
    end
  end
end

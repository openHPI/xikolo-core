# frozen_string_literal: true

module Collabspace
  class CollabspacePresenter < Presenter
    extend RestifyForwardable

    include Collabspace::ConstantsHelper
    include Rails.application.routes.url_helpers
    include ActionView::Helpers::UrlHelper
    include MarkdownHelper

    require 'digest/md5'

    attr_accessor :collabspace, :course, :include_calendar, :members, :membership, :membership_status,
      :request, :space_admins_total, :super_privileged, :team_peer_assessments

    def_restify_delegators :collabspace, :description, :kind

    def self.create(collabspace, course, options = {})
      user_memberships = options[:user_memberships] || []
      membership_status = determine_membership_status(collabspace, user_memberships)
      space_admins_total = user_memberships.count {|membership| membership['status'] == MEMBERSHIP_TYPE[:admin] }

      new(
        collabspace:,
        course:,
        members: user_memberships,
        membership: options[:membership],
        request: options[:request],
        team_peer_assessments: options[:team_peer_assessments] || [],
        include_calendar: options[:include_calendar] || false,
        super_privileged: options[:super_privileged] || false,
        membership_status:,
        space_admins_total:
      )
    end

    def collabspace_id
      collabspace['id']
    end

    def details
      render_markdown(collabspace['details'])
    end

    def course_id
      course.id
    end

    def course_code
      course.course_code
    end

    def open?
      collabspace['is_open']
    end

    def name
      if team?
        I18n.t(:'learning_rooms.team_name', name: collabspace['name'])
      else
        collabspace['name']
      end
    end

    def team?
      kind == 'team'
    end

    def can_quit?(current_user)
      member = member(current_user)
      !team? && member.present? && !last_space_admin?(member)
    end

    def membership_pending?
      !membership.nil? && membership['status'] == 'pending'
    end

    def can_join?
      !team?
    end

    def join_url
      course_learning_room_memberships_path(course_id, collabspace_id)
    end

    def index_action_button_type
      return if team?

      case membership_status
        when :member, :pending
          :collab_space
        when :join, :request_membership
          :collab_space_memberships
      end
    end

    def index_action_button
      return {} if team?

      labels = {
        member: I18n.t(:'learning_rooms.go'),
        pending: I18n.t(:'learning_rooms.pending'),
        join: I18n.t(:'learning_rooms.join'),
        request_membership: I18n.t(:'learning_rooms.request'),
      }

      button_params = {
        member: {class: 'btn btn-sm btn-success'},
        pending: {class: 'btn btn-sm btn-primary full-width'},
        join: {class: 'btn btn-sm btn-primary action-button-auto-width'},
        request_membership: {class: 'btn btn-sm btn-primary action-button-auto-width'},
      }

      {
        url_params: {course_id: collabspace['course_id'], learning_room_id: collabspace_id},
        label: labels[membership_status],
        button_params: button_params[membership_status],
      }.compact
    end

    def table_of_contents
      @table_of_contents ||= Navigation::TableOfContents.for_collabspace(
        context: self,
        request:
      )
    end

    def self.determine_membership_status(collabspace, user_memberships)
      corresponding_membership = user_memberships.find do |membership|
        membership['learning_room_id'] == collabspace['id']
      end
      concrete_membership_status(collabspace, corresponding_membership)
    end

    def self.concrete_membership_status(collabspace, corresponding_membership)
      if corresponding_membership
        existing_membership corresponding_membership
      else
        become_a_member_stati collabspace
      end
    end

    def self.existing_membership(corresponding_membership)
      status = corresponding_membership['status']
      MEMBERSHIP_TYPE.include?(status) ? :member : status.to_sym
    end

    def self.become_a_member_stati(collabspace)
      collabspace['is_open'] ? :join : :request_membership
    end

    private

    def member(current_user)
      members.find {|membership| membership['user_id'] == current_user.id }
    end

    def space_admin?(member)
      member['status'] == MEMBERSHIP_TYPE[:admin]
    end

    def last_space_admin?(member)
      space_admin?(member) && space_admins_total < 2
    end
  end
end

# frozen_string_literal: true

module Collabspace
  class CollabspacesController < Abstract::FrontendController
    include Interruptible

    include Collabspace::FullCollabspacesControllerCommon
    include CourseContextHelper
    include Collabspace::CollabspaceHelper
    include Collabspace::ConstantsHelper

    layout LAYOUTS[:course_area]

    PER_PAGE = 50

    before_action :ensure_logged_in
    before_action :ensure_admin, only: %i[edit update destroy]
    before_action :check_course_path, only: :show

    inside_course except: %i[create update destroy]

    def index
      @course = the_course
      Restify::Promise.new [
        collabspace_api.rel(:collab_spaces)
          .get(user_id: current_user.id,
            course_id: @course.id,
            with_membership: 'false',
            per_page: PER_PAGE,
            page: current_page,
            sort: 'name'),
        collabspace_api.rel(:collab_spaces)
          .get(user_id: current_user.id,
            course_id: @course.id,
            with_membership: 'true'),
      ] do |unjoined_collabspaces, my_collabspaces|
        @my_collabspace_presenters = wrap_in_presenters my_collabspaces
        @unjoined_collabspaces = unjoined_collabspaces
        @collabspace_presenters = wrap_in_presenters @unjoined_collabspaces
      end.value!

      Acfs.run

      set_page_title the_course.title, t(:'courses.nav.learning_rooms')
    end

    # Dashboard - View recent activity
    def show
      Acfs.run # because of `inside_course`

      @memberships = approved_memberships
      @members = approved_members
      @collabspace_presenter = build_collabspace_presenter(
        collabspace:,
        memberships: @memberships,
        load_tpa: true
      )

      set_page_title the_course.title, t(:'courses.nav.learning_rooms')

      if member? || current_user.allowed?('course.course.teaching_anywhere')
        render layout: LAYOUTS[:course_area_two_cols]
      else
        render 'join', layout: LAYOUTS[:course_area]
      end
    end

    def new
      Acfs.run # because of `inside_course`

      @collabspace = Collabspace::CollabspacesForm.new

      set_page_title the_course.title, t(:'courses.nav.learning_rooms')
    end

    # ---------------
    # | ADMIN STUFF |
    # ---------------

    # Administration - Manage your Collab Space
    def edit
      Acfs.run # because of `inside_course`

      @memberships = all_memberships
      @members = all_members
      @collabspace_presenter = build_collabspace_presenter(
        collabspace:,
        memberships: @memberships,
        load_tpa: true
      )

      @collabspace = Collabspace::CollabspacesForm.new(collabspace)
      @new_membership = Collabspace::MembershipForm.new

      set_page_title the_course.title, t(:'courses.nav.learning_rooms')
      render layout: LAYOUTS[:course_area_two_cols]
    end

    def create
      form = Collabspace::CollabspacesForm.new \
        collabspace_params.merge(
          owner_id: current_user.id,
          course_id: the_course.id,
          kind: 'group'
        )

      # re-render creation form if there are errors
      unless form.save
        @collabspace = form
        return render(action: :new)
      end

      redirect_to course_learning_room_path(the_course.course_code, form.id)
    end

    def update
      is_open = collabspace_params['is_open']
      name = collabspace_params['name']
      description = collabspace_params['description']
      details = collabspace_params['details']
      collabspace_params = {
        id: collabspace['id'],
        course_id: collabspace['course_id'],
        is_open:,
        name:,
        kind: collabspace['kind'],
        description:,
        details:,
      }

      form = Collabspace::CollabspacesForm.new(collabspace_params)
      form.save
      redirect_to course_learning_room_path(the_course.course_code, collabspace['id'])
    end

    def destroy
      if collabspace['kind'] == 'team'
        add_flash_message :error, I18n.t('learning_rooms.flash_messages.error.delete_space')
        return redirect_to(action: :index)
      end

      collabspace.rel(:self).delete.value!

      add_flash_message :success, I18n.t('learning_rooms.flash_messages.success.delete_room')
      redirect_to(action: :index)
    end

    private

    def check_course_path
      Acfs.on the_course do |course|
        if collabspace['course_id'] != course.id
          raise Status::NotFound
        end
      end
    end

    def auth_context
      the_course.context_id
    end

    def collabspace_params
      params.require(:collabspace).permit(:name, :description, :details, :is_open)
    end

    def current_page
      (params[:page] || 1).to_i
    end

    def wrap_in_presenters(collabspaces)
      collabspaces.map do |collabspace|
        build_collabspace_presenter(
          collabspace:,
          memberships: course_memberships
        )
      end
    end

    def course_memberships
      @course_memberships ||= collabspace_api
        .rel(:memberships)
        .get(user_id: current_user.id, course_id: @course.id)
        .value!
    end

    def all_memberships
      @all_memberships ||= collabspace_memberships
    end

    def all_members
      @all_members ||= members_for(memberships: all_memberships)
    end

    def approved_memberships
      @approved_memberships ||= collabspace_memberships(
        # Restify does not send hashes in GET params (that concept does not exist
        # in HTTP), so we have to build them by hand following the convention the
        # server-side expects. YOLO.
        MEMBERSHIP_TYPE.transform_keys {|key| "status[#{key}]" }
      )
    end

    def approved_members
      @approved_members ||= members_for(memberships: approved_memberships)
    end

    def members_for(memberships:)
      return [] if memberships.empty?

      present_members_for memberships
    end

    def collabspace_memberships(additional_query_params = {})
      collabspace_api.rel(:memberships).get(
        {
          collab_space_id: collabspace_id,
          per_page: PER_PAGE,
          page: params[:page] || 1,
        }.merge(additional_query_params)
      ).value!
    end

    def present_members_for(memberships)
      members_by_user_id = memberships.index_by {|membership| membership['user_id'] }
      member_ids = members_by_user_id.keys
      Xikolo::Account::User.find member_ids do |member_users|
        member_users = [member_users] unless member_users.respond_to? :each
        @presented_members = member_users.each.map do |user|
          Collabspace::MemberPresenter.new user:, membership: members_by_user_id[user.id]
        end
      end
      Acfs.run

      @presented_members
    end

    def collabspace_id
      # The collabspace id is required for shared methods in the (Full)CollabspacesControllerCommon
      params[:id]
    end

    def collabspace
      @collabspace ||= collabspace_api.rel(:collab_space).get(id: collabspace_id).value!
    end

    def collabspace_api
      @collabspace_api ||= Xikolo.api(:collabspace).value!
    end
  end
end

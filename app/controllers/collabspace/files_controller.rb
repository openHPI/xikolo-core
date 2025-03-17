# frozen_string_literal: true

module Collabspace
  class FilesController < Abstract::FrontendController
    include CourseContextHelper
    include Collabspace::FullCollabspacesControllerCommon
    include Collabspace::ConstantsHelper

    inside_course

    before_action :ensure_logged_in
    before_action :ensure_collabspace_membership

    def index
      Acfs.run # because of `inside_course`

      @collabspace_presenter = build_collabspace_presenter(
        collabspace:,
        memberships: user_memberships
      )

      files = collabspace.rel(:files).get(per_page:, page: current_page).value!
      @files = Collabspace::FilesListPresenter.new files, current_user, collabspace
      @new_file = Collabspace::FileForm.new

      set_page_title the_course.title, t(:'courses.nav.learning_rooms')
      render 'collabspace/files/index', layout: LAYOUTS[:course_area_two_cols]
    end

    def create
      Acfs.run

      form = FileForm.from_params(params)

      return redirect_to(action: :index) unless form.valid?

      file = form.to_resource
      upload_name = params.dig('collabspace_file', 'file_upload_name')

      collabspace.rel(:files).post(
        title: upload_name,
        creator_id: current_user.id,
        upload_uri: "upload://#{file['file_upload_id']}/#{upload_name}"
      ).value!

      redirect_to action: :index
    rescue Restify::ClientError
      # Fail silently and rely on the error indicator for the upload dropzone for now
      # TODO: Re-design upload process and error handling
    end

    def destroy
      authorize_file_deletion!

      file.rel(:self).delete.value!

      add_flash_message :success, t(:'flash.notice.file_deleted')
      redirect_to action: :index
    rescue Restify::NotFound
      add_flash_message :error, t(:'flash.error.files.file_missing')
      redirect_to action: :index
    end

    private

    def auth_context
      the_course.context_id
    end

    def collabspace_id
      # The collabspace id is required for shared methods in the (Full)CollabspacesControllerCommon
      params[:learning_room_id]
    end

    def collabspace_api
      @collabspace_api ||= Xikolo.api(:collabspace).value!
    end

    def collabspace
      @collabspace ||= collabspace_api.rel(:collab_space).get(id: collabspace_id).value!
    end

    def file
      @file ||= collabspace_api.rel(:file).get(id: params[:id]).value!
    end

    def authorize_file_deletion!
      return if file['creator_id'] == current_user.id
      return if privileged?
      return if current_user.allowed?('collabspace.file.manage')

      raise Status::Unauthorized
    end

    def current_page
      (params[:page] || 1).to_i
    end

    def per_page
      params[:per_page].try(:to_i) || 10
    end
  end
end

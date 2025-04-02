# frozen_string_literal: true

class ItemsController < Abstract::FrontendController
  include CourseContextHelper
  include ItemContextHelper

  before_action :set_no_cache_headers

  include Interruptible
  before_action :ensure_content_editor, except: :show
  before_action :load_user_preferences, only: :show, if: proc {|_| current_user.authenticated? }

  inside_course
  inside_item only: :show
  before_action :load_section_nav

  respond_to :json, :xml

  def request_section
    if params[:action] == 'show'
      promise, fulfiller = create_promise(Xikolo::Course::Section.new)
      Acfs.on the_item do |item|
        Xikolo::Course::Section.find item.section_id do |section|
          fulfiller.fulfill section
        end
      end
      promise
    else
      super
    end
  end

  def request_item
    return dummy_resource_delegator nil unless params[:id]
    raise Status::NotFound if (uuid = UUID4.try_convert(params[:id])).nil?

    Xikolo::Course::Item.find(
      uuid,
      params: {}.tap do |p|
        # Authorized users (e.g., course admins) can always access items, but
        # for regular learners the user-specific access is verified.
        p[:user_id] = current_user.id unless current_user.allowed? 'course.content.access'

        p[:for_user] = current_user.id if current_user.feature? 'course.reactivated'
      end
    )
  end

  def show
    Acfs.run

    return render('error') if @item_presenter.error
    return @item_presenter.redirect(self) if @item_presenter.redirect?

    # The QuizSubmissionController takes care of creating visits for quizzes
    create_visit! unless @item_presenter.content_type == 'quiz'

    meta = @item_presenter.meta_tags
    set_page_title(*meta.delete(:title))
    set_meta_tags meta

    return render('requirements') if @item_presenter.required_items.present?

    render layout: @item_presenter.layout
  rescue Acfs::ResourceNotFound => e
    operation = e.response.request.operation
    raise unless operation.resource == Xikolo::Course::Item &&
                 operation.action == :read

    raise AbstractController::ActionNotFound
  end

  def new
    @item ||= Xikolo::Course::Item.new # lazy initialization is used to re-render when create fails
    @item.published = true

    @video ||= Video::Video.new
    @rich_text ||= Course::Richtext.new
    @quiz ||= Xikolo::Quiz::Quiz.new
    @lti_exercise ||= Lti::Exercise.new

    # for nav and stuff
    @course ||= the_course

    Acfs.on @course do |course|
      @course_presenter = CoursePresenter.create(@course, current_user)

      @sections ||= course.sections do |sections|
        sections.each(&:items)
      end

      @lti_providers_global ||= Lti::Provider.global
      @lti_providers_course ||= Lti::Provider.where(course_id: course.id)
    end

    @navsec ||= Xikolo::Course::Section.find(params[:section_id]) do |section|
      @items ||= section.items
    end
    @section = @navsec

    create_video_uploads!
    Acfs.run

    render 'new', layout: 'course_area'
  end

  def edit
    @item = Xikolo::Course::Item.find UUID(params[:id]), params: {raw: 1} do |item|
      case @item.content_type
        when 'video'
          @video = Video::Video.find(item.content_id)
        when 'rich_text'
          @rich_text = Course::Richtext.find(item.content_id)
        when 'quiz'
          # Dummy resources to be used for the initial blank form (dynamically
          # rendered based on the selected quiz type).
          @quiz_question = Xikolo::Quiz::Question.new
          @multiple_choice_question = Xikolo::Quiz::MultipleChoiceQuestion.new
          @multiple_answer_question = Xikolo::Quiz::MultipleAnswerQuestion.new
          @free_text_question = Xikolo::Quiz::FreeTextQuestion.new
          @essay_question = Xikolo::Quiz::EssayQuestion.new(exclude_from_recap: true)
          @question_count = 0

          @quiz = Xikolo::Quiz::Quiz.find(@item.content_id, params: {raw: true}) do |quiz|
            @quiz_total_points = quiz.max_points
            quiz.enqueue_acfs_request_for_questions do |questions|
              questions.each do |question|
                @question_count += 1
                question.enqueue_acfs_request_for_answers
              end
            end
          end
        when 'lti_exercise'
          @lti_exercise = Lti::Exercise.find(item.content_id)
          Acfs.on the_course do |course|
            @lti_providers_global ||= Lti::Provider.global
            @lti_providers_course ||= Lti::Provider.where(course_id: course.id)
          end
      end
    end
    @course = Xikolo::Course::Course.find params[:course_id] do |course|
      @sections = Xikolo::Course::Section.where course_id: course.id
      @course_presenter = CoursePresenter.create course, current_user
    end
    create_video_uploads!
    Acfs.run

    render 'edit', layout: 'course_area'
  end

  def create
    @item = Xikolo::Course::Item.new item_params

    # Check whether the content type supports open mode and featured.
    # Flash a message if selected but not supported.
    unless valid_content_type_attributes?
      add_flash_message :error, t(:'flash.error.content_type_not_supported_options')
      new
      return
    end

    case item_params[:content_type]
      when 'video'
        @content = @video = Video::Store.call(Video::Video.new, content_video_params)
        if @video.errors.any?
          add_flash_message :error, I18n.t('items.errors.create')
          new
          return
        end
      when 'rich_text'
        Acfs.on the_course do |course|
          @content = @rich_text = Course::Richtext::Store.call(Course::Richtext.new,
            content_richtext_params.merge(course_id: course.id))
        end
        if @rich_text.errors.any?
          add_flash_message :error, I18n.t('items.errors.create')
          new
          return
        end
      when 'quiz'
        @content = @quiz = Xikolo::Quiz::Quiz.new content_quiz_params
      when 'lti_exercise'
        @content = @lti_exercise = Lti::Exercise::Store.call(Lti::Exercise.new, content_lti_params)
    end

    # Make sure both the course and section are loaded
    the_course
    the_section
    Acfs.run

    # Persist the item and the corresponding content resource.
    # The content resource may already be persisted depending on the content type.
    # I.e. video and lti exercise items are already persisted at this point.
    begin
      item = Item::Create.call(item: @item, content: @content, section: the_section)
    rescue Item::Create::ContentCreationError => e
      e.errors.each do |msg|
        msg[1].each do |m|
          @content.errors.add(msg[0], m)
        end
      end
      add_flash_message :error, I18n.t('items.errors.create')

      new
      return
    end

    # If there are errors for the item resource, display them as flash messages.
    # Errors may also be attached to the content resource attributes directly,
    # i.e. displayed inline in the form. In this case, error messages will not be
    # displayed as flash messages. There may be inconsistencies between content
    # types in regard to the error handling.
    if item.errors.any?
      item.errors.messages.each do |msg|
        message = if msg[0] == :base
                    msg[1][0]
                  else
                    t(:"errors.messages.item.#{msg[0]}.#{msg[1][0]}")
                  end
        add_flash_message :error, message
      end
      return redirect_to new_course_section_item_path
    end

    # Apply the proper redirect depending on the content type
    if item_params[:content_type] == 'quiz'
      return redirect_to edit_course_section_item_path id: item.id
    end

    redirect_to course_sections_path
  end

  def update
    @item = Xikolo::Course::Item.find UUID(params[:id]) do |item|
      case @item.content_type
        when 'video'
          @video = Video::Video.find item.content_id
        when 'rich_text'
          @rich_text = Course::Richtext.find item.content_id
        when 'quiz'
          @quiz = Xikolo::Quiz::Quiz.find item.content_id
        when 'lti_exercise'
          @lti_exercise = Lti::Exercise.find item.content_id
      end
    end

    Acfs.run

    # This is needed to re-render the item when validations fail.

    @course ||= the_course

    Acfs.on @course do |course|
      @course_presenter = CoursePresenter.create(@course, current_user)

      @sections ||= course.sections do |sections|
        sections.each(&:items)
      end

      @lti_providers_global ||= Lti::Provider.global
      @lti_providers_course ||= Lti::Provider.where(course_id: course.id)
    end

    # Check whether the content type supports open mode and featured
    # and flash a message if selected but not supported
    unless valid_content_type_attributes?
      add_flash_message :error, t(:'flash.error.content_type_not_supported_options')
      edit
      return
    end

    @item.attributes = item_params
    unless @item.save
      @item.errors.messages.each do |msg|
        add_flash_message :error, t("errors.messages.item.#{msg[0]}.#{msg[1][0]}")
      end
      return redirect_to edit_course_section_item_path
    end

    case @item.content_type
      when 'video'
        @video = Video::Store.call(@video, content_video_params)
        if @video.errors.any?
          # Specific errors were attached by the operation to the video resource to be displayed inline in the form
          add_flash_message :error, I18n.t('items.errors.update')
          create_video_uploads!
          render 'edit', layout: 'course_area'
          return
        end
      when 'rich_text'
        @rich_text = Course::Richtext::Store.call(@rich_text, content_richtext_params)
        if @rich_text.errors.any?
          add_flash_message :error, I18n.t('items.errors.update')
          render 'edit', layout: 'course_area'
          return
        end
      when 'quiz'
        @quiz.attributes = content_quiz_params
        @quiz.save!
      when 'lti_exercise'
        @lti_exercise = Lti::Exercise::Store.call(@lti_exercise, content_lti_params)
        if @lti_exercise.errors.any?
          render 'edit', layout: 'course_area'
          return
        end
    end

    if params[:show]
      redirect_to course_item_path id: short_uuid(@item.id)
    else
      add_flash_message :success, I18n.t('items.update.success')
      redirect_to edit_course_section_item_path
    end
  rescue Acfs::InvalidResource
    add_flash_message :error, I18n.t('items.errors.update')
    redirect_to edit_course_section_item_path
  end

  def move
    if Course::Course.find(the_course.id).legacy?
      Xikolo::Course::Item.find params[:id] do |item|
        # if item is moved to a different section
        # note we cannot use section_id as param as this is already used by the nested ressource itself

        case params[:position]
          when 'up'
            item.update_attributes({position: item.position - 1})
          when 'down'
            item.update_attributes({position: item.position + 1})
          when 'top'
            item.update_attributes({position: 1})
          when 'bottom'
            Xikolo::Course::Item.where(section_id: item.section_id) do |resource|
              resource.update_attributes({position: item.map(&:position).max + 1})
            end
          else
            # Add one as client items are indexed starting at zero while
            # service starts at one
            item.update_attributes({position: params[:position].to_i + 1})
        end

        next unless params[:new_section_id] && params[:_newsection_id] != item.section_id

        item.update_attributes({
          section_id: params[:new_section_id],
          position: params[:position].to_i + 1,
        })
      end
      Acfs.run

    else
      return if params[:new_section_node_id].blank? && params[:left_sibling].blank? && params[:right_sibling].blank?

      node = Course::Item.find(params[:id]).node
      if params[:new_section_node_id]
        section_node = Course::Structure::Node.find(params[:new_section_node_id])
        node.item.update(section: section_node.section)
        node.move_to_child_of(section_node)
      end

      if params[:left_sibling].present?
        node.move_to_right_of(Course::Structure::Node.find(params[:left_sibling]))
      elsif params[:right_sibling].present?
        node.move_to_left_of(Course::Structure::Node.find(params[:right_sibling]))
      end
    end
    request.xhr? ? head(:ok) : redirect_to(course_sections_path)
  end

  def destroy
    item = Xikolo::Course::Item.find params[:id] do |resource|
      case resource.content_type
        when 'quiz'
          Xikolo::Quiz::Quiz.find(resource.content_id, &:delete!)
          @notice = I18n.t('items.deleted_quiz')
        when 'rich_text'
          @content = Course::Richtext.find(resource.content_id)
        when 'lti_exercise'
          @content = Lti::Exercise.find(resource.content_id)
        when 'video'
          @content = Video::Video.find(resource.content_id)
        else
          @notice = I18n.t('items.deleted_item')
      end
    end
    Acfs.run

    # Destroy the item via `xi-course` (ItemsController#destroy) to
    # trigger callbacks on destroy that are only available in the
    # service model. Once, `xi-quiz` are part of the monolith, we can
    # destroy the `Course::Item` record in `xi-web`, which also triggers
    # the destruction of the content.
    item.delete!

    # Quizzes are destroyed by `xi-quiz`.
    unless %w[quiz].include?(item.content_type)
      @content.destroy!
      @notice = I18n.t('items.deleted_item')
    end

    redirect_to course_sections_path, notice: @notice
  end

  def hide_course_nav?
    # Only show the course nav in the learner-facing page (the show page)
    @_action_name != 'show'
  end

  private

  def check_course_eligibility
    return super unless params[:action] == 'show'

    Acfs.on the_item do |item|
      # TODO: we restrict open mode to video items for now; this restriction will have to be removed later
      super unless item.open_mode
    end
  end

  def multi_language_zip?(file)
    zip_mimetypes = %w[
      application/zip
      application/x-zip-compressed
      application/x-compressed
      multipart/x-zip
      application/octet-stream
    ]
    # checking the file ending is necessary as .vtt files also have the mimetype 'application/octet-stream'
    zip_mimetypes.include?(file.content_type) &&
      File.extname(file.original_filename) == '.zip'
  end

  def vtt?(file)
    File.extname(file.original_filename) == '.vtt'
  end

  def auth_context
    the_course.context_id
  end

  def item_params
    params.require(:xikolo_course_item).permit(
      :content_id,
      :content_type,
      :end_date,
      :exercise_type,
      :featured,
      :icon_type,
      :max_points,
      :open_mode,
      :optional,
      :proctored,
      :public_description,
      :published,
      :section_id,
      :show_in_nav,
      :start_date,
      :submission_deadline,
      :submission_publishing_date,
      :title,
      required_item_ids: []
    ).tap do |p|
      # The required_item_ids parameter is collected from a multi-select input,
      # which may include an extra hidden input field.
      #
      # This may result in an empty string being included in the array sent to the backend.
      # If no hidden input is present and all options are deselected,
      # the parameter is not sent at all.
      #
      # To handle both cases, we set the parameter to an empty array by default
      # and remove any empty strings.
      p[:required_item_ids] = Array.wrap(p[:required_item_ids]).compact_blank
    end
  end

  def content_video_params
    permitted_params = params.require(:video).permit(
      # File uploads:
      :description,
      :subtitles_upload_id,
      :slides_upload_id,
      :reading_material_upload_id,
      :transcript_upload_id,
      # Whether to remove attached files:
      :slides_url,
      :reading_material_url,
      :transcript_url,
      # Stream ID references:
      :lecturer_stream_id,
      :slides_stream_id,
      :pip_stream_id,
      :subtitled_stream_id,
      # Stream URI references:
      :slides_uri,
      :reading_material_uri,
      :transcript_uri
    )
    # Convert empty string values for urls to nil, to allow removing the
    # attached files in the video service
    %w[transcript_url slides_url reading_material_url].each do |field|
      next unless params[:video].key? field

      permitted_params[field] = nil if params[:video][field].blank?
    end

    # Re-use the item's title for the video
    permitted_params[:title] = item_params[:title]

    permitted_params
  end

  def load_user_preferences
    Xikolo::Account::Preferences.find user_id: current_user.id do |preferences|
      @user_preferences = preferences
    end
  end

  def content_quiz_params
    params.require(:xikolo_quiz_quiz).permit(
      :allowed_attempts,
      :instructions,
      :time_limit_seconds,
      :unlimited_attempts,
      :unlimited_time
    )
  end

  def content_lti_params
    params.require(:lti_exercise).permit(
      :custom_fields,
      :instructions,
      :lti_provider_id,
      :title
    )
  end

  def content_richtext_params
    params.require(:course_richtext).permit(:text)
  end

  def create_video_uploads!
    # TODO: reuse passed in upload ids?
    @subtitles_upload = FileUpload.new(purpose: :video_subtitles, content_type: %w[application/zip text/vtt])
    @slides_upload = FileUpload.new purpose: :video_slides
    @reading_material_upload = FileUpload.new purpose: :video_material
    @transcript_upload = FileUpload.new purpose: :video_transcript
  end

  def course_api
    @course_api ||= Xikolo.api(:course).value!
  end

  def valid_content_type_attributes?
    # Videos can be featured or be available in open mode
    return true if item_params[:content_type] == 'video'

    # The other content types are not supported
    !ActiveModel::Type::Boolean.new.cast(item_params[:featured]) &&
      !ActiveModel::Type::Boolean.new.cast(item_params[:open_mode])
  end
end
# rubocop:enable all

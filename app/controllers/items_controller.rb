# frozen_string_literal: true

class ItemsController < Abstract::FrontendController
  include CourseContextHelper
  include ItemContextHelper
  include QuizQuestionsHelper

  include Interruptible

  before_action :ensure_content_editor, except: %i[show signed_url]
  before_action :load_user_preferences, only: :show, if: proc {|_| current_user.authenticated? }

  inside_course
  inside_item only: :show
  before_action :load_section_nav, except: :destroy

  respond_to :json, :xml

  def request_section
    if params[:action] == 'show'
      course_api.rel(:section).get({id: UUID(item['section_id'])})
    else
      super
    end
  end

  def request_item
    return nil unless params[:id]
    raise Status::NotFound if (uuid = UUID4.try_convert(params[:id])).nil?

    get_params = {id: uuid.to_s}.tap do |p|
      # Authorized users (e.g., course admins) can always access items, but
      # for regular learners the user-specific access is verified.
      p[:user_id] = current_user.id unless current_user.allowed? 'course.content.access'
      p[:for_user] = current_user.id if current_user.feature? 'course.reactivated'
    end

    course_api.rel(:item).get(get_params)
  end

  def show
    Acfs.run

    return render('error') if @item_presenter.error
    return @item_presenter.redirect(self) if @item_presenter.redirect?

    # The QuizSubmissionController takes care of creating visits for quizzes
    create_visit! unless @item_presenter.quiz?

    meta = @item_presenter.meta_tags
    set_page_title(*meta.delete(:title))
    set_meta_tags meta

    return render('requirements') if @item_presenter.required_items.present?

    render layout: @item_presenter.layout
  end

  # Redirects to a freshly signed Bunny CDN URL for the item's video stream,
  # mirroring `ShortsController#signed_url`. Access is gated by the same
  # course/item availability checks as the item page itself.
  def signed_url
    course = the_course
    item = the_item.value!
    record = CourseService::Item.find(item['id'])
    # `check_course_path` does not run for this action, so verify the item
    # belongs to the course in the URL to avoid cross-course access.
    raise Status::NotFound unless record.section.course_id == course.id

    stream = record.content.bunny_stream if record.video?
    raise Status::NotFound if stream.nil?

    redirect_to BunnySignedURL.new.call(stream.provider_video_id).fetch(:video), allow_other_host: true
  end

  def new(status: nil)
    @item ||= CourseService::Item.new
    @item.published = true

    @video ||= Video::Video.new
    @rich_text ||= CourseService::Richtext.new
    @quiz ||= Xikolo::Quiz::Quiz.new
    @lti_exercise ||= Lti::Exercise.new
    @cmi5_item ||= Cmi5::Item.new

    # for nav and stuff
    @course ||= the_course

    @course_presenter = CoursePresenter.create(@course, current_user)

    @sections ||= @course.sections do |sections|
      sections.each(&:items)
    end

    @lti_providers_global ||= Lti::Provider.global
    @lti_providers_course ||= Lti::Provider.where(course_id: @course.id)

    @navsec ||= CourseService::Section.find(params[:section_id])
    @items ||= @navsec.items
    @section = @navsec

    create_video_uploads!
    create_richtext_uploads!
    Acfs.run
    if status
      render 'new', layout: 'course_area', status:
    else
      render 'new', layout: 'course_area'
    end
  end

  def edit(status: nil)
    @item = CourseService::Item.find(UUID(params[:id]).to_s)
    case @item.content
      when Video::Video
        @video = @item.content
      when CourseService::Richtext
        @rich_text = @item.content
      when QuizService::Quiz
        load_quiz_content!(@item)
      when Lti::Exercise
        @lti_exercise = @item.content
        @lti_providers_global ||= Lti::Provider.global
        @lti_providers_course ||= Lti::Provider.where(course_id: the_course.id)
      when Cmi5::Item
        @cmi5_item = @item.content
    end
    Acfs.run

    if @item.exercise_type == 'exam'
      redirect_to edit_exam_course_section_item_path(
        course_id: the_course.id,
        section_id: @item.section_id,
        id: @item.id
      ), status: :see_other
      return
    end

    @course ||= the_course
    @sections = @course.sections.to_a
    @course_presenter = CoursePresenter.create(@course, current_user)
    create_video_uploads!
    create_richtext_uploads!
    Acfs.run
    if status
      render 'edit', layout: 'course_area', status:
    else
      render 'edit', layout: 'course_area'
    end
  end

  def new_exam(status: nil)
    @exam = true
    @item ||= CourseService::Item.new(
      content: QuizService::Quiz.new, exercise_type: 'exam', published: false, minimum_progress_percentage: 75
    )
    @quiz ||= Xikolo::Quiz::Quiz.new(question_pool: true, time_limit_seconds: 3600, allowed_attempts: 2,
      pass_percentage: 70)
    load_exam_form_context
    Acfs.run

    render 'new_exam', layout: 'course_area', status:
  end

  def edit_exam(status: nil)
    @exam = true
    @item = CourseService::Item.find(UUID(params[:id]).to_s)
    load_quiz_content!(@item)

    load_exam_form_context
    Acfs.run

    if status
      render 'edit_exam', layout: 'course_area', status:
    else
      render 'edit_exam', layout: 'course_area'
    end
  end

  def create
    @item = CourseService::Item.new item_params
    @exam = item_params[:exercise_type] == 'exam'

    # Check whether the content type supports open mode.
    # Flash a message if selected but not supported.
    unless valid_content_type_attributes?
      add_flash_message :error, t(:'flash.error.content_type_not_supported_options')
      render_exam_or_new_form(status: :unprocessable_entity)
      return
    end

    case item_params[:content_type]
      when 'Video::Video'
        @content = @video = Video::Store.call(Video::Video.new, content_video_params)
        if @video.errors.any?
          add_flash_message :error, I18n.t('items.errors.create')
          new(status: :unprocessable_entity)
          return
        end
      when 'CourseService::Richtext'
        course = the_course
        @content = @rich_text = Course::Richtext::Store.call(CourseService::Richtext.new,
          content_richtext_params.merge(course_id: course.id))
        if @rich_text.errors.any?
          add_flash_message :error, I18n.t('items.errors.create')
          new(status: :unprocessable_entity)
          return
        end
      when 'QuizService::Quiz'
        @content = @quiz = Xikolo::Quiz::Quiz.new content_quiz_params
      when 'Lti::Exercise'
        @content = @lti_exercise = Lti::Exercise::Store.call(Lti::Exercise.new, content_lti_params)
      when 'Cmi5::Item'
        @content = @cmi5_item = Cmi5::Item.create(content_cmi5_params)
        if @cmi5_item.errors.any?
          add_flash_message :error, I18n.t('items.errors.create')
          new(status: :unprocessable_entity)
          return
        else
          Cmi5ItemUnzipJob.perform_later(@cmi5_item)
        end
    end

    # Exams (question-pool quizzes) have a fixed number of points per attempt,
    # derived from the displayed question set. Set it automatically when the
    # editor left it empty.
    @item.max_points = displayed_max_points(@quiz) if @exam && @quiz && @item.max_points.blank?

    # Make sure the course is loaded
    the_course
    Acfs.run

    # Persist the item and the corresponding content resource.
    # The content resource may already be persisted depending on the content type.
    # I.e. video and lti exercise items are already persisted at this point.
    begin
      item = Item::Create.call(item: @item, content: @content, section:)
    rescue Item::Create::ContentCreationError => e
      e.errors.each do |msg|
        msg[1].each do |m|
          @content.errors.add(msg[0], m)
        end
      end
      add_flash_message :error, I18n.t('items.errors.create')

      render_exam_or_new_form(status: :unprocessable_entity)
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
      render_exam_or_new_form(status: :unprocessable_entity)
      return
    end

    # Apply the proper redirect depending on the content type
    if item_params[:content_type] == 'QuizService::Quiz'
      if @exam
        return redirect_to(edit_exam_course_section_item_path(
          course_id: the_course.id,
          section_id: @item.section_id,
          id: @item.id
        ), status: :see_other)
      end

      return redirect_to(edit_course_section_item_path(id: item.id), status: :see_other)
    end

    redirect_to course_sections_path, status: :see_other
  end

  def update
    @item = CourseService::Item.find(UUID(params[:id]).to_s)
    case @item.content
      when Video::Video
        @video = @item.content
      when CourseService::Richtext
        @rich_text = @item.content
      when QuizService::Quiz
        load_quiz_content!(@item)
      when Lti::Exercise
        @lti_exercise = @item.content
      when Cmi5::Item
        @cmi5_item = @item.content
    end

    Acfs.run

    @exam = @item.exercise_type == 'exam'

    # This is needed to re-render the item when validations fail.

    @course ||= the_course

    @course_presenter = CoursePresenter.create(@course, current_user)
    @sections ||= @course.sections.to_a
    @lti_providers_global ||= Lti::Provider.global
    @lti_providers_course ||= Lti::Provider.where(course_id: @course.id)

    # Check whether the content type supports open mode
    # and flash a message if selected but not supported
    unless valid_content_type_attributes?
      add_flash_message :error, t(:'flash.error.content_type_not_supported_options')
      render_edit_form(status: :unprocessable_entity)
      return
    end

    @item.attributes = item_params
    if @item.quiz?
      @quiz.attributes = content_quiz_params
      # Exams (question-pool quizzes) have a fixed number of points per attempt,
      # derived from the displayed question set. Keep it in sync on every save.
      if @exam && (points = displayed_max_points(@quiz))
        @item.max_points = points
      end
      unless quiz_pool_valid?
        add_flash_message :error,
          t(quiz_pool_validation_message, errors: quiz_pool_validation_errors.to_sentence)
        if @item.published
          render_edit_form(status: :unprocessable_entity)
          return
        end
      end
    end
    unless @item.save
      # `max_dpoints` is an internal implementation detail (decipoints);
      # errors are surfaced to users under the `max_points` attribute they entered.
      if @item.errors.include?(:max_dpoints)
        @item.errors.delete(:max_dpoints).each {|msg| @item.errors.add(:max_points, msg) }
      end

      @item.errors.messages.each do |msg|
        add_flash_message :error, t("errors.messages.item.#{msg[0]}.#{msg[1][0]}")
      end
      return redirect_to edit_item_path, status: :see_other
    end

    case @item.content
      when Video::Video
        @video = Video::Store.call(@video, content_video_params)
        if @video.errors.any?
          # Specific errors were attached by the operation to the video resource to be displayed inline in the form
          add_flash_message :error, I18n.t('items.errors.update')
          create_video_uploads!
          render 'edit', layout: 'course_area', status: :unprocessable_content
          return
        end
      when CourseService::Richtext
        @rich_text = Course::Richtext::Store.call(@rich_text, content_richtext_params)
        if @rich_text.errors.any?
          add_flash_message :error, I18n.t('items.errors.update')
          create_richtext_uploads!
          render 'edit', layout: 'course_area', status: :unprocessable_content
          return
        end
      when QuizService::Quiz
        @quiz.save!
      when Lti::Exercise
        @lti_exercise = Lti::Exercise::Store.call(@lti_exercise, content_lti_params)
        if @lti_exercise.errors.any?
          render 'edit', layout: 'course_area', status: :unprocessable_content
          return
        end
      when Cmi5::Item
        @cmi5_item.update(content_cmi5_params)
        if @cmi5_item.errors.any?
          render 'edit', layout: 'course_area', status: :unprocessable_content
          return
        elsif content_cmi5_params[:package].present?
          Cmi5ItemUnzipJob.perform_later(@cmi5_item)
        end
    end

    if params[:show]
      redirect_to course_item_path(id: short_uuid(@item.id)), status: :see_other
    else
      add_flash_message :success, I18n.t('items.update.success')
      redirect_to edit_item_path, status: :see_other
    end
  rescue Acfs::InvalidResource
    add_flash_message :error, I18n.t('items.errors.update')
    redirect_to edit_item_path, status: :see_other
  end

  def move
    if CourseService::Course.find(the_course.id).legacy?
      item = CourseService::Item.find(params[:id])

      # if item is moved to a different section
      # note we cannot use section_id as param as this is already used by the nested ressource itself
      case params[:position]
        when 'up'
          item.update(position: item.position - 1)
        when 'down'
          item.update(position: item.position + 1)
        when 'top'
          item.update(position: 1)
        when 'bottom'
          max_position = CourseService::Item.where(section_id: item.section_id).maximum(:position)
          item.update(position: max_position + 1)
        else
          # Add one as client items are indexed starting at zero while
          # service starts at one
          item.update(position: params[:position].to_i + 1)
      end

      if params[:new_section_id] && params[:_newsection_id] != item.section_id
        item.update(
          section_id: params[:new_section_id],
          position: params[:position].to_i + 1
        )
      end

    else
      return if params[:new_section_node_id].blank? && params[:left_sibling].blank? && params[:right_sibling].blank?

      node = CourseService::Item.find(params[:id]).node
      if params[:new_section_node_id]
        section_node = CourseService::Structure::Node.find(params[:new_section_node_id])
        node.item.update(section: section_node.section)
        node.move_to_child_of(section_node)
      end

      if params[:left_sibling].present?
        node.move_to_right_of(CourseService::Structure::Node.find(params[:left_sibling]))
      elsif params[:right_sibling].present?
        node.move_to_left_of(CourseService::Structure::Node.find(params[:right_sibling]))
      end
    end
    request.xhr? ? head(:ok) : redirect_to(course_sections_path, status: :see_other)
  end

  def destroy
    item = course_api.rel(:item).get({id: UUID4(params[:id]).to_s}).then do |resource|
      case resource['content_type']
        when 'QuizService::Quiz'
          Xikolo.api(:quiz).value!.rel(:quiz).delete({id: resource['content_id']})
          @notice = I18n.t('items.deleted_quiz')
        when 'CourseService::Richtext'
          @content = CourseService::Richtext.find(resource['content_id'])
        when 'Lti::Exercise'
          @content = Lti::Exercise.find(resource['content_id'])
        when 'Video::Video'
          @content = Video::Video.find(resource['content_id'])
        when 'Cmi5::Item'
          @content = Cmi5::Item.find(resource['content_id'])
        else
          @notice = I18n.t('items.deleted_item')
      end
      resource
    end.value!

    # Destroy the item via `xi-course` (ItemsController#destroy) to
    # trigger callbacks on destroy that are only available in the
    # service model. Once, `xi-quiz` is part of the monolith, we can
    # destroy the `CourseService::Item` record in `xi-web`, which also triggers
    # the destruction of the content.
    course_api.rel(:item).delete({id: item['id']}).value!

    # Quizzes are destroyed by `xi-quiz`.
    unless %w[QuizService::Quiz].include?(item['content_type'])
      @content.destroy!
      @notice = I18n.t('items.deleted_item')
    end

    redirect_to course_sections_path, notice: @notice, status: :see_other
  end

  private

  # Exams are created through a dedicated form (not the general item form).
  # Re-render that form when creating an exam fails.
  def render_exam_or_new_form(status: nil)
    if @exam
      load_exam_form_context
      Acfs.run
      render 'new_exam', layout: 'course_area', status:
    else
      new(status:)
    end
  end

  def edit_item_path
    if @exam
      edit_exam_course_section_item_path(id: @item.id)
    else
      edit_course_section_item_path(id: @item.id)
    end
  end

  def render_edit_form(status: nil)
    if @exam
      # Set up the view context the dedicated exam page needs (mirrors `edit_exam`).
      load_exam_form_context
      Acfs.run
      render 'edit_exam', layout: 'course_area', status:
    else
      render 'edit', layout: 'course_area', status:
    end
  end

  def load_quiz_content!(item)
    load_quiz_dummy_resources
    @quiz = Xikolo::Quiz::Quiz.find(item.content.id, params: {raw: true}) do |quiz|
      quiz.enqueue_acfs_request_for_questions do |questions|
        questions.each(&:enqueue_acfs_request_for_answers)
      end
    end
    @quiz_info = item.content
  end

  # Dummy resources used to render the blank question forms.
  def load_quiz_dummy_resources
    @quiz_question = Xikolo::Quiz::Question.new
    @multiple_choice_question = Xikolo::Quiz::MultipleChoiceQuestion.new
    @multiple_answer_question = Xikolo::Quiz::MultipleAnswerQuestion.new
    @free_text_question = Xikolo::Quiz::FreeTextQuestion.new
    @essay_question = Xikolo::Quiz::EssayQuestion.new(exclude_from_recap: true)
  end

  # Shared setup for the dedicated exam create/edit pages (mirrors `#new`).
  def load_exam_form_context
    load_quiz_dummy_resources

    @course ||= the_course
    @sections ||= @course.sections.to_a
    @course_presenter = CoursePresenter.create(@course, current_user)
    @lti_providers_global ||= Lti::Provider.global
    @lti_providers_course ||= Lti::Provider.where(course_id: @course.id)

    @navsec ||= CourseService::Section.find(params[:section_id])
    @items ||= @navsec.items
    @section = @navsec
  end

  def check_course_eligibility
    return super unless params[:action] == 'show'

    # TODO: we restrict open mode to video items for now; this restriction will have to be removed later
    the_item.then do |item|
      super unless item['open_mode']
    end&.value!
  rescue Restify::NotFound
    super # See if there is already another more fitting reason to redirect, e.g. a missing enrollment

    # This will redirect to the last visited item or to the first public or to the course info
    raise Status::Redirect.new 'Item not available', course_resume_path(the_course.id)
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

  def quiz_pool_valid?
    return true unless @quiz.question_pool

    quiz_pool_candidate.valid_question_pool?
  end

  def quiz_pool_validation_message
    return :'items.quiz.exam_invalid_message' if @item.published

    :'items.quiz.exam_draft_message'
  end

  def quiz_pool_validation_errors
    quiz_pool_candidate.errors.full_messages
  end

  def quiz_pool_candidate
    @quiz_pool_candidate ||= QuizService::Quiz.find(@quiz.id).tap do |quiz|
      quiz.assign_attributes(content_quiz_params)
    end
  end

  def item_params
    params.require(:xikolo_course_item).permit(
      :content_id,
      :content_type,
      :deemphasized_in_nav,
      :end_date,
      :exercise_type,
      :max_points,
      :minimum_progress_percentage,
      :open_mode,
      :optional,
      :public_description,
      :published,
      :section_id,
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
    permitted_params = params.require(:video_video).permit(
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
      next unless params[:video_video].key? field

      permitted_params[field] = nil if params[:video_video][field].blank?
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
      :unlimited_time,
      :question_pool,
      :displayed_question_count,
      :pass_percentage
    ).tap do |p|
      p[:question_pool] = true if @exam # force question pool for exams
    end
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
    params.require(:richtext).permit(
      :text,
      :reading_material_upload_id,
      :reading_material_url
    )
  end

  def content_cmi5_params
    # The `cmi5` scope holds only the file input, which is not submitted when no
    # file is selected. The fallback ({}) avoids `ActionController::ParameterMissing`.
    params.fetch(:cmi5, {}).permit(:package)
  end

  def create_video_uploads!
    # TODO: reuse passed in upload ids?
    @subtitles_upload = FileUpload.new(purpose: :video_subtitles, content_type: %w[application/zip text/vtt])
    @slides_upload = FileUpload.new purpose: :video_slides
    @reading_material_upload = FileUpload.new purpose: :video_material
    @transcript_upload = FileUpload.new purpose: :video_transcript
  end

  def create_richtext_uploads!
    @richtext_reading_material_upload = FileUpload.new(purpose: :richtext_material)
  end

  def course_api
    @course_api ||= Xikolo.api(:course).value!
  end

  def valid_content_type_attributes?
    # Videos can be available in open mode
    return true if item_params[:content_type] == 'Video::Video'

    # The other content types are not supported
    !ActiveModel::Type::Boolean.new.cast(item_params[:open_mode])
  end
end
# rubocop:enable all

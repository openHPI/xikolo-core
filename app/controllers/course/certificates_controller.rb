# frozen_string_literal: true

class Course::CertificatesController < Abstract::FrontendController
  include Interruptible

  include CourseContextHelper
  inside_course except: :verify

  before_action :ensure_logged_in, except: :verify
  before_action(only: :index) do
    next if current_user.feature?('course.certificates_tab')

    raise AbstractController::ActionNotFound
  end

  def index
    Acfs.run

    Acfs.on the_course do |course|
      @achievements = Restify.new(course['achievements_url']).get(
        params: {user_id: current_user.id},
        headers: {'Accept-Language' => I18n.locale}
      ).value!
    end

    @documents = Course::DocumentsPresenter.new(user_id: current_user.id, course: the_course, current_user:)

    Acfs.run
  end

  def show
    Acfs.run

    @record = Certificate::RecordPresenter.new(
      Certificate::Template.find_by!(
        course_id: the_course.id,
        certificate_type: Certificate::Record::ROA
      ).record_for!(current_user.id),
      :show
    )

    @open_badge = Certificate::OpenBadgeTemplate
      .find_by(course_id: the_course.id)
      &.bake!(current_user.id)

    set_meta_tags certificate_meta_tags

    gon.course_id = the_course.id
    render template: 'course/certificates/verify'
  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotFound
    raise AbstractController::ActionNotFound
  end

  def render_certificate
    record = Certificate::Template.find_by!(
      course_id: params[:course_id],
      certificate_type: params[:type]
    ).record_for!(current_user.id)

    # Additional authorization for certificate download requests.
    ensure_proctoring_passed!(record) if render_certificate?

    send_data(
      Certificate::Record::Render.call(record),
      type: 'application/pdf',
      disposition: 'attachment',
      filename: "#{record.course.course_code}_#{params[:type]}.pdf"
    )
  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotFound, CertificateNotAllowed
    raise AbstractController::ActionNotFound
  end

  def verify
    @record = Certificate::Record.verify(params[:id])
    @open_badge = if @record.eligible_for_badge?
                    Certificate::OpenBadgeTemplate
                      .find_by(course_id: @record.course_id)
                      &.bake!(@record.user_id)
                  end

    set_meta_tags certificate_meta_tags unless @record.user_deleted?
    set_meta_tags(noindex: true)
  rescue ActiveRecord::RecordNotFound
    raise AbstractController::ActionNotFound
  end

  private

  def render_certificate?
    params[:type] == Certificate::Record::CERT
  end

  # If a course is proctored but proctoring has not been passed by the user,
  # do not render (i.e. allow downloading) the certificate.
  # @param record [Certificate::Template]
  def ensure_proctoring_passed!(record)
    return unless record.course.proctored?

    enrollment = Course::Enrollment.find_by(
      user_id: current_user.id,
      course_id: record.course_id
    )
    return if enrollment&.proctored &&
              Proctoring::SmowlAdapter.new(record.course).passed?(current_user)

    raise CertificateNotAllowed
  end

  def check_course_eligibility
    return if current_user.allowed?('course.content.access')

    # TODO: Improve checks
    if !the_course.was_available?
      # The course has not been published, so the user could
      # not gain a certificate.
      raise Status::NotFound
    elsif action_name == 'index' && !current_user.allowed?('course.content.access.available')
      add_flash_message :error, I18n.t(:'flash.error.not_enrolled')
      redirect_to course_url(the_course.course_code)
    end
  end

  def auth_context
    return super if params[:action] == 'verify'

    the_course.context_id
  end

  def certificate_meta_tags
    meta_tags = {
      title: "#{I18n.t(:'verify.headline_show')} - #{@record.course_title}",
      description: I18n.t(
        :'verify.narrative_meta',
        title: @record.course_title,
        brand: Xikolo.config.site_name
      ),
      og: {
        title: "#{I18n.t(:'verify.headline_show')} - #{@record.course_title}",
        type: 'website',
        url: certificate_verification_url(@record.verification_code),
        description: I18n.t(
          :'verify.narrative_meta',
          title: @record.course_title,
          brand: Xikolo.config.site_name
        ),
        site_name: Xikolo.config.site_name,
      },
    }

    if @open_badge
      meta_tags[:og][:image] = @open_badge.file_url
      meta_tags[:og]['image:secure_url'] = @open_badge.file_url
    end

    meta_tags
  end

  class CertificateNotAllowed < RuntimeError; end
end

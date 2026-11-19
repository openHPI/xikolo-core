# frozen_string_literal: true

class Course::CertificatesController < Abstract::FrontendController
  include Interruptible

  include CourseContextHelper

  inside_course except: :verify

  before_action :ensure_logged_in, except: :verify

  def show
    Acfs.run

    @record = Certificate::RecordPresenter.new(
      Certificate::Template.find_by!(
        course_id: the_course.id,
        certificate_type: Certificate::Record::ROA
      ).record_for!(current_user.id),
      :show
    )

    set_meta_tags certificate_meta_tags

    render template: 'course/certificates/verify'
  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotFound
    raise AbstractController::ActionNotFound
  end

  def render_certificate
    record = Certificate::Template.find_by!(
      course_id: params[:course_id],
      certificate_type: params[:type]
    ).record_for!(current_user.id)

    send_data(
      Certificate::Record::Render.call(record),
      type: 'application/pdf',
      disposition: 'attachment',
      filename: "#{record.course.course_code}_#{params[:type]}.pdf"
    )
  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotFound
    raise AbstractController::ActionNotFound
  end

  def verify
    @record = Certificate::Record.verify(params[:id])

    set_meta_tags certificate_meta_tags unless @record.user_deleted?
    set_meta_tags(noindex: true)
  rescue ActiveRecord::RecordNotFound
    raise AbstractController::ActionNotFound
  end

  private

  # Certificates can be downloaded (e.g. from /dashboard/documents) even if the
  # course is in preparation, so skip the course availability checks.
  def check_course_eligibility; end

  def auth_context
    return super if params[:action] == 'verify'

    the_course.context_id
  end

  def certificate_meta_tags
    {
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
  end
end

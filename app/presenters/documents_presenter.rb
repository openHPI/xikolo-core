# frozen_string_literal: true

class DocumentsPresenter < Presenter
  attr_accessor :enrollment, :course, :user

  def self.create(enrollment, user)
    new(enrollment:, user:).tap do |presenter|
      presenter.course!
      presenter.templates!
    end
  end

  def course!
    @course = course_api.rel(:course).get({id: enrollment.course_id}).then do |course|
      BasicCoursePresenter.new(course)
    end.value!
  end

  def templates!
    @templates ||= {}.tap do |templates|
      if enrollment.certificates[:confirmation_of_participation]
        templates[:confirmation_of_participation] = template_for(type: Certificate::Record::COP)
      end

      if enrollment.certificates[:record_of_achievement]
        templates[:record_of_achievement] = template_for(type: Certificate::Record::ROA)
        templates[:open_badge] = Certificate::OpenBadgeTemplate.find_by(course_id: enrollment.course_id)
      end

      if enrollment.certificates[:transcript_of_records]
        templates[:transcript_of_records] = template_for(type: Certificate::Record::TOR)
      end

      if enrollment.proctored? && enrollment.certificates[:certificate]
        templates[:certificate] = template_for(type: Certificate::Record::CERT)
      end
    end
  end

  def open_badge?
    open_badge_enabled? && roa?
  end

  def open_badge_enabled?
    template?(:open_badge)
  end

  def cop?
    enrollment.certificates[:confirmation_of_participation] &&
      template?(:confirmation_of_participation)
  end

  def roa?
    enrollment.certificates[:record_of_achievement] &&
      template?(:record_of_achievement)
  end

  def cert?
    enrollment.proctored? &&
      enrollment.certificates[:certificate] &&
      template?(:certificate)
  end

  def tor?
    enrollment.certificates[:transcript_of_records] &&
      template?(:transcript_of_records)
  end

  def tor_available?
    template?(:transcript_of_records)
  end

  def cert_enabled?
    user.feature?('proctoring') &&
      Proctoring.enabled? &&
      enrollment.proctored?
  end

  def user_passed_proctoring?
    Proctoring::SmowlAdapter.new(
      Course::Course.where(deleted: false).find(enrollment.course_id)
    ).passed?(@user)
  end

  def certificate_download?
    # Allow to download the certificate when
    # the document has been created and proctoring has been passed
    cert_enabled? && cert? && user_passed_proctoring?
  end

  def divergent_certificate_requirements?
    course.roa_threshold_percentage != Xikolo.config.roa_threshold_percentage ||
      course.cop_threshold_percentage != Xikolo.config.cop_threshold_percentage
  end

  def any_available?
    course.certificates_enabled?
  end

  def published?
    course.certificates_published?
  end

  private

  def course_api
    RequestStore.store[:course_root] ||= Xikolo.api(:course).value!
  end

  def template_for(type:)
    Certificate::Template.find_by(course_id: course.id, certificate_type: type)
  end

  def template?(type)
    # This presenter is also used without the `.create` class method,
    # so calling `templates!` ensures that they are loaded correctly.
    templates!
    return false unless @templates.key? type

    @templates[type].present?
  end
end

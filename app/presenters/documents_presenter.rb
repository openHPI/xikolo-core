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
      if certificates[:confirmation_of_participation]
        templates[:confirmation_of_participation] = template_for(type: Certificate::Record::COP)
      end

      if certificates[:record_of_achievement]
        templates[:record_of_achievement] = template_for(type: Certificate::Record::ROA)
      end

      if certificates[:certificate]
        templates[:certificate] = template_for(type: Certificate::Record::CERT)
      end
    end
  end

  def cop?
    certificates[:confirmation_of_participation] &&
      template?(:confirmation_of_participation)
  end

  def roa?
    certificates[:record_of_achievement] &&
      template?(:record_of_achievement)
  end

  def cert?
    certificates[:certificate] &&
      template?(:certificate)
  end

  def cert_enabled?
    cert?
  end

  def certificate_download?
    cert?
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

  def certificates
    @certificates ||= enrollment.decorate_self[:certificates] || {}
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

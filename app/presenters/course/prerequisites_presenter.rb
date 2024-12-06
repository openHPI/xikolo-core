# frozen_string_literal: true

class Course::PrerequisitesPresenter
  def initialize(course, status)
    @course = course
    @status = status
  end

  def any?
    @status && @status['prerequisites'].any?
  end

  def each(&)
    all.each(&)
  end

  def status
    all.all?(&:fulfilled?) ? 'complete' : 'incomplete'
  end

  def status_text
    I18n.t(:'courses.prerequisites.status_text', count: all.count(&:missing?))
  end

  def status_icon_name
    status == 'complete' ? 'check' : 'times'
  end

  def all
    @all ||= @status['prerequisites'].map {|req| Item.new(@course, req) }
  end

  class Item
    def initialize(course, prerequisite)
      @course = course
      @prerequisite = prerequisite
    end

    def render(ctx)
      ctx.render(
        'course/courses/prerequisite',
        prerequisite: self,
        course: prerequisite_course,
        course_url: ctx.course_url(prerequisite_course['course_code']),
        free_reactivation_url: ctx.course_free_reactivations_url(@course)
      )
    end

    def fulfilled?
      @prerequisite['fulfilled']
    end

    def missing?
      !fulfilled?
    end

    def facts
      facts = []

      if fulfilled?
        facts << {
          state: 'completed',
          icon_name: 'check',
          html: I18n.t(:"courses.prerequisites.facts.fulfilled_#{@prerequisite['required_certificate']}"),
        }
      else
        facts << {
          state: 'missing',
          icon_name: 'xmark',
          html: I18n.t(:"courses.prerequisites.facts.missing_#{@prerequisite['required_certificate']}"),
        }
      end

      facts
    end

    def free_reactivation?
      @prerequisite['free_reactivation']
    end

    private

    def prerequisite_course
      @prerequisite['course']
    end
  end
end

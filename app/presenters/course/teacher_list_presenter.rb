# frozen_string_literal: true

class Course::TeacherListPresenter
  def self.for_course(course)
    promise = if course.teacher_ids.empty?
                Restify::Promise.fulfilled([])
              else
                Xikolo.api(:course).value!.rel(:teachers).get(course: course.id)
              end

    new promise
  end

  def initialize(teachers_promise)
    @teachers_promise = teachers_promise
  end

  def pagination
    RestifyPaginationCollection.new all
  end

  def display?
    !all.empty?
  end

  def each
    all.each_with_index do |teacher, i|
      yield TeacherPresenter.new(teacher, active: i == 0)
    end
  end

  private

  def all
    @teachers_promise.value!
  end

  class TeacherPresenter
    def initialize(teacher, active: false)
      @teacher = teacher
      @active = active
    end

    def id
      @teacher['id']
    end

    def name
      @teacher['name']
    end

    def picture_url
      @teacher['picture_url']
    end
    alias picture? picture_url

    def active?
      @active
    end

    def description
      return nil if @teacher['description'].nil?

      [
        I18n.locale.to_s,
        Xikolo.config.locales['default'],
        *Xikolo.config.locales['available'],
      ].each do |locale|
        if @teacher['description'].key? locale
          return @teacher['description'][locale]
        end
      end
      nil
    end

    def descriptions(&)
      return if @teacher['description'].nil?

      @teacher['description'].each(&)
    end

    def description?
      description.present?
    end
  end
end

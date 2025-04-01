# frozen_string_literal: true

class Course
  attr_reader :code, :language

  def initialize(attrs)
    @code = attrs.fetch('course_code')
    @language = attrs.fetch('lang', 'en')
  end

  def admins
    Xikolo.api(:account).value!
      .rel(:group).get({id: "course.#{code}.admins"}).value!
      .rel(:members).get.value!
  end

  class << self
    def find(id)
      new fetch(id)
    end

    def delete(id)
      Rails.cache.delete "pinboard/v1/course/#{id}"
    end

    private

    def fetch(id)
      Rails.cache.fetch("pinboard/v1/course/#{id}", expires_in: 1.day) do
        Xikolo.api(:course).value!.rel(:course).get({id:}).value!.data
      end
    rescue Restify::NotFound
      raise NotFound
    end
  end

  class NotFound < StandardError; end
end

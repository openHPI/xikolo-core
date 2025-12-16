# frozen_string_literal: true

module CourseService
class LtiExercise::Clone < ApplicationOperation # rubocop:disable Layout/IndentationWidth
  def initialize(exercise, new_course_id)
    super()

    @exercise = exercise
    @new_course_id = new_course_id
  end

  def call
    attrs = @exercise.attributes.except('id')
    attrs['lti_provider_id'] = new_provider.id

    exercise = Duplicated::LtiExercise.new attrs

    exercise.instructions = copy_files(exercise.instructions)
    exercise.save!

    exercise
  end

  private

  def new_provider
    old_provider = @exercise.lti_provider

    return old_provider if old_provider.global?

    new_provider = Duplicated::LtiProvider.find_by \
      name: old_provider.name,
      course_id: @new_course_id

    return new_provider if new_provider

    provider_attrs = old_provider.attributes.except('id')
    provider_attrs['course_id'] = @new_course_id

    Duplicated::LtiProvider.create! provider_attrs
  end

  def copy_files(markup)
    file_cache = {}
    markup&.gsub(Xikolo::S3.url_regex) do |match|
      next file_cache[match] if file_cache.key? match

      original = Xikolo::S3.object(match)
      # Replace exercise ID in key
      key = original.key.split('/').tap do |parts|
        parts[1] = UUID4(@exercise.id).to_s(format: :base62)
      end.join('/')

      file_cache[match] = Xikolo::S3.copy_to(original, target: key, bucket: :lti, acl: 'public-read')
    end
  end
end
end

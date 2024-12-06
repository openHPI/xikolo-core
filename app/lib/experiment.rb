# frozen_string_literal: true

class Experiment
  def initialize(identifier, course_id: nil)
    @identifier = identifier
    @course_id = course_id
  end

  def assign!(user, exclude_groups: nil)
    return DefaultAssignment.new(user) if user.anonymous?
    return DefaultAssignment.new(user) unless Xikolo.api?(:grouping)

    assignment = Xikolo.api(:grouping).value!.rel(:user_assignments).post(
      {
        course_id: @course_id,
        identifier: @identifier,
        exclude_groups:,
      }.compact,
      user_id: user.id
    ).value!

    AssignmentResult.new(user, assignment)
  rescue Restify::NetworkError
    # Do not fail if grouping service is not available
    DefaultAssignment.new(user)
  end

  class AssignmentResult
    def initialize(user, assignment)
      @user = user
      @assignment = assignment
    end

    # The assignment returns *newly acquired features* only.
    # If the user is already assigned to a group, we want to delegate to
    # the current user features, which will include *all* features.
    def feature?(name)
      features.key?(name.to_s) || @user.feature?(name)
    end

    private

    def features
      @assignment['features']
    end
  end

  class DefaultAssignment
    def initialize(user)
      @user = user
    end

    def feature?(name)
      @user.feature?(name)
    end
  end
end

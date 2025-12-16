# frozen_string_literal: true

module CourseService
class ContentTest < ApplicationRecord # rubocop:disable Layout/IndentationWidth
  self.table_name = :content_tests

  IDENTIFIER_REGEXP = /\A[[:alnum:]]+(-[[:alnum:]]+)*\z/

  belongs_to :course
  has_many :forks, dependent: :restrict_with_exception

  validates :identifier,
    presence: true,
    uniqueness: {scope: :course, message: 'Identifier has already been used for this course'},
    format: IDENTIFIER_REGEXP
  validates :groups, length: {minimum: 2, message: 'Test should include at least two groups'}
  validate :alphanumeric_group_names, :groups_are_unique

  after_create :create_groups

  def group_for_user(user_id)
    assigned_group(user_id) || assign(user_id)
  end

  ##
  # Iterate over the user groups belonging to this content test.
  #
  # Yields the internal group identifier as well as the group model.
  #
  def with_groups
    hash = Duplicated::Group.where(name: group_names).index_by(&:name)

    groups.each do |identifier|
      yield identifier, hash[build_group_name(identifier)]
    end
  end

  private

  def create_groups
    with_groups do |group_identifier, group|
      group ||= Duplicated::Group.new(name: build_group_name(group_identifier))
      group.tags.push('content_test') unless group.tags.include?('content_test')
      group.save!
    end
  end

  def group_names
    groups.map {|group| build_group_name(group) }
  end

  def build_group_name(group_identifier)
    "course.#{course.course_code}.content_test.#{identifier}.#{group_identifier}"
  end

  def assigned_group(user_id)
    Duplicated::Membership.joins(:group).find_by(user_id:, groups: {name: group_names})&.group_id
  end

  # Atomically assign a user to the next group (by round robin).
  # Round robin assignment must be wrapped in an exclusive row lock to prevent race conditions.
  def assign(user_id)
    with_lock do
      # #group_for_user does not prevent race conditions, so we need to check once more whether
      # another thread has created a membership for this user. Hereafter, the exclusive lock will
      # prevent further race conditions.
      group_id = assigned_group(user_id)
      next group_id if group_id

      round_robin do |next_group_id|
        Duplicated::Membership.create!(user_id:, group_id: next_group_id)
      end
    end
  end

  def round_robin
    group = Duplicated::Group.find_by!(name: group_names[round_robin_counter])

    yield group.id

    next_value = round_robin_counter + 1
    next_value = 0 if next_value >= groups.size
    update(round_robin_counter: next_value)

    group.id
  end

  def alphanumeric_group_names
    unless groups.all? {|group| group.match?(IDENTIFIER_REGEXP) }
      errors.add :groups, :invalid_name, message: 'Only alphanumeric characters and dash allowed'
    end
  end

  def groups_are_unique
    if groups.uniq.count < groups.count
      errors.add :groups, :duplicates, message: 'Duplicate groups are not allowed'
    end
  end
end
end

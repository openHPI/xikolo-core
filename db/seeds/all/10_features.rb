# frozen_string_literal: true

# Default feature flippers
%w[
  account.login
  account.registration
  alternative_sections.create
  announcements
  certificate_requirements
  course.access-group
  course_details.learning_goals
  course_list
  course_rating
  course_reactivation
  gamification
  ical_feed
  open_mode
  proctoring
  profile
  time_effort
  quiz_recap
  video_slide_thumbnails
].each do |feature|
  AccountService::Feature.find_or_create_by!(
    name: feature,
    value: true,
    owner: AccountService::Group.all_users,
    context: AccountService::Context.root
  )
end

# Admin-only feature flippers
%w[
  admin_announcements
  course.required_items
].each do |feature|
  AccountService::Feature.find_or_create_by!(
    name: feature,
    value: true,
    owner: AccountService::Group.administrators,
    context: AccountService::Context.root
  )
end

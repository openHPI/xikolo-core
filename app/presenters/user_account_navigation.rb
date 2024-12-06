# frozen_string_literal: true

class UserAccountNavigation < MenuWithPermissions
  item 'header.navigation.dashboard', 'grid-2',
    route: :dashboard

  item 'header.navigation.profile', 'user',
    if: ->(user, _course) { user.feature?('profile') },
    route: :dashboard_profile

  item 'header.navigation.documents', 'medal',
    route: :dashboard_documents

  item 'header.navigation.achievements', 'trophy',
    if: ->(user, _course) { user.feature?('gamification') },
    route: :dashboard_achievements

  item 'header.navigation.settings', 'gear',
    route: :preferences
end

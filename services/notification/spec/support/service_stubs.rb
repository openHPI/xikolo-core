# frozen_string_literal: true

RSpec.configure do |config|
  config.before(:each) do
    Stub.service(
      :account,
      user_url: 'http://localhost:3100/users/{id}',
      users_url: 'http://localhost:3100/users{?search,query,blurb,archived,confirmed,id}',
      authorization_url: 'http://localhost:3100/authorizations/{id}',
      authorizations_url: 'http://localhost:3100/authorizations',
      group_url: 'http://localhost:3100/groups/{id}',
      groups_url: 'http://localhost:3100/groups',
      member_url: 'http://localhost:3100/members/{id}',
      members_url: 'http://localhost:3100/members',
      password_reset_url: 'http://localhost:3100/password_resets/{id}'
    )

    Stub.service(
      :course,
      items_current_url: 'http://localhost:3300/items/current',
      item_user_visit_url: 'http://localhost:3300/items/{item_id}/users/{user_id}/visit',
      item_user_results_url: 'http://localhost:3300/items/{item_id}/users/{user_id}/results',
      items_url: 'http://localhost:3300/items',
      item_url: 'http://localhost:3300/items/{id}',
      result_url: 'http://localhost:3300/results/{id}',
      course_statistic_url: 'http://localhost:3300/courses/{course_id}/statistic',
      course_persist_ranking_task_url: 'http://localhost:3300/courses/{course_id}/persist_ranking_task',
      courses_url: 'http://localhost:3300/courses{?cat_id,user_id,status,id,lang,course_code,upcoming,current,finished,public,latest_first}',
      course_url: 'http://localhost:3300/courses/{id}',
      next_dates_url: 'http://localhost:3300/next_dates',
      categories_url: 'http://localhost:3300/categories',
      category_url: 'http://localhost:3300/categories/{id}',
      sections_url: 'http://localhost:3300/sections',
      section_url: 'http://localhost:3300/sections/{id}',
      enrollments_url: 'http://localhost:3300/enrollments{?course_id,user_id}',
      enrollment_url: 'http://localhost:3300/enrollments/{id}',
      system_info_url: 'http://localhost:3300/system_info/{id}',
      progresses_url: 'http://localhost:3300/progresses',
      stats_url: 'http://localhost:3300/stats'
    )
  end
end

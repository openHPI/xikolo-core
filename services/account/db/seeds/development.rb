# frozen_string_literal: true

# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

# == Users

require 'xikolo/config'

AccountService::User.create!(
  id: '00000001-3100-4444-9999-000000000001',
  full_name: 'Kevin Cool Jr.',
  display_name: 'Kevin Cool',
  password: 'qwe123qwe',
  born_at: Date.new(1985, 4, 24),
  status: 'school_student'
).tap do |user|
  user.emails.create!(
    address: 'kevin.cool@example.com',
    primary: true,
    confirmed: true
  )
end

AccountService::User.create!(
  id: '00000001-3100-4444-9999-000000000002',
  full_name: 'Adam Administrator',
  display_name: 'A. Admin',
  password: 'administrator',
  status: 'teacher'
).tap do |user|
  user.adminize!

  user.emails.create!(
    address: 'admin@example.com',
    primary: true,
    confirmed: true
  )
end

AccountService::User.create!(
  id: '00000001-3100-4444-9999-000000000003',
  full_name: 'Tom T. Teacher',
  password: 'teaching',
  status: 'teacher'
).tap do |user|
  user.emails.create!(
    address: 'tom@example.com',
    primary: true,
    confirmed: true
  )
end

AccountService::User.create!(
  id: '00000001-3100-4444-9999-000000000004',
  full_name: 'Conrad Adenauer',
  display_name: 'C. Adenauer',
  password: 'qwe123qwe',
  language: 'de',
  status: 'other'
).tap do |user|
  user.emails.create!(
    address: 'conrad@example.com',
    primary: true,
    confirmed: true
  )
end

AccountService::User.create!(
  id: '00000001-3100-4444-9999-000000000005',
  full_name: 'Jimmy Cheng',
  display_name: 'Jimmy CHENG',
  password: 'qwe123qwe',
  language: 'en',
  status: 'other'
).tap do |user|
  user.emails.create!(
    address: 'cheng@example.de',
    primary: true,
    confirmed: true
  )
end

AccountService::User.create!(
  id: '00000001-3100-4444-9999-000000000006',
  full_name: 'Uncle Uncool Sr.',
  display_name: 'Uncle Uncool',
  password: 'qwe123qwe',
  born_at: Date.new(1985, 4, 24),
  status: 'other'
).tap do |user|
  user.emails.create!(
    address: 'uncle.uncool@example.com',
    primary: true,
    confirmed: true
  )
end

200.times do |i|
  AccountService::User.create!(
    id: format('00000001-3100-4444-9999-0000000%05d', i + 100),
    full_name: 'John Smith',
    display_name: "U_#{i} Smith",
    password: 'johnsmith'
  ).tap do |user|
    user.emails.create!(
      address: "john.smith#{i}@example.com",
      primary: true,
      confirmed: true
    )
  end
end

# == Users for Tatort / Peer Assessment seeds

AccountService::User.create!(
  id: '00000001-3100-4444-9999-000000002001',
  full_name: 'Till Ritter',
  password: 'tatort123',
  display_name: 'Kommissar Ritter',
  language: 'en',
  confirmed: true,
  status: 'other'
).tap do |user|
  user.emails.create!(
    address: 'ritter@tatort.de',
    primary: true,
    confirmed: true
  )
end

AccountService::User.create!(
  id: '00000001-3100-4444-9999-000000002002',
  full_name: 'Karl-Friedrich Börne',
  password: 'tatort123',
  display_name: 'Kommissar Boerne',
  language: 'en',
  confirmed: true,
  status: 'other'
).tap do |user|
  user.emails.create!(
    address: 'boerne@tatort.de',
    primary: true,
    confirmed: true
  )
end

AccountService::User.create!(
  id: '00000001-3100-4444-9999-000000002003',
  full_name: 'Klaus Borowski',
  password: 'tatort123',
  display_name: 'Kommissar Borowski',
  language: 'en',
  confirmed: true,
  status: 'other'
).tap do |user|
  user.emails.create!(
    address: 'borowski@tatort.de',
    primary: true,
    confirmed: true
  )
end

AccountService::User.create!(
  id: '00000001-3100-4444-9999-000000002004',
  full_name: 'Sarah Brandt',
  password: 'tatort123',
  display_name: 'Kommissar Brandt',
  language: 'en',
  confirmed: true,
  status: 'other'
).tap do |user|
  user.emails.create!(
    address: 'brandt@tatort.de',
    primary: true,
    confirmed: true
  )
end

AccountService::User.create!(
  id: '00000001-3100-4444-9999-000000002005',
  full_name: 'Bibi Fellner',
  password: 'tatort123',
  display_name: 'Kommissar Fellner',
  language: 'en',
  confirmed: true,
  status: 'other'
).tap do |user|
  user.emails.create!(
    address: 'fellner@tatort.de',
    primary: true,
    confirmed: true
  )
end

AccountService::User.create!(
  id: '00000001-3100-4444-9999-000000002006',
  full_name: 'Frank Thiel',
  password: 'tatort123',
  display_name: 'Kommissar Thiel',
  language: 'en',
  confirmed: true,
  status: 'other'
).tap do |user|
  user.emails.create!(
    address: 'thiel@tatort.de',
    primary: true,
    confirmed: true
  )
end

AccountService::User.create!(
  id: '00000001-3100-4444-9999-000000002007',
  full_name: 'Moritz Eisner',
  password: 'tatort123',
  display_name: 'Kommissar Eisner',
  language: 'en',
  confirmed: true,
  status: 'other'
).tap do |user|
  user.emails.create!(
    address: 'eisner@tatort.de',
    primary: true,
    confirmed: true
  )
end

AccountService::User.create!(
  id: '00000001-3100-4444-9999-000000002008',
  full_name: 'Peter Faber',
  password: 'tatort123',
  display_name: 'Kommissar Faber',
  language: 'en',
  confirmed: true,
  status: 'other'
).tap do |user|
  user.emails.create!(
    address: 'faber@tatort.de',
    primary: true,
    confirmed: true
  )
end

AccountService::User.create!(
  id: '00000001-3100-4444-9999-000000002009',
  full_name: 'Martina Bönisch',
  password: 'tatort123',
  display_name: 'Kommissar Bönisch',
  language: 'en',
  confirmed: true,
  status: 'other'
).tap do |user|
  user.emails.create!(
    address: 'boenisch@tatort.de',
    primary: true,
    confirmed: true
  )
end

AccountService::User.create!(
  id: '00000001-3100-4444-9999-000000002010',
  full_name: 'Felix Stark',
  password: 'tatort123',
  display_name: 'Kommissar Stark',
  language: 'en',
  confirmed: true,
  status: 'other'
).tap do |user|
  user.emails.create!(
    address: 'stark@tatort.de',
    primary: true,
    confirmed: true
  )
end

AccountService::Treatment.create!(
  name: 'marketing',
  required: false
)

# Ensure profile permissions
AccountService::User.find_each(&:update_profile_completion!)

# Default feature flippers
%w[
  account.login
  account.registration
  announcements
  certificate_requirements
  course_details.learning_goals
  course_list
  course_reactivation
  gamification
  open_mode
  proctoring
  profile
  time_effort
  quiz_recap
].each do |feature|
  AccountService::Feature.create!(
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
  users.search_by_auth_uid
].each do |feature|
  AccountService::Feature.create!(
    name: feature,
    value: true,
    owner: AccountService::Group.administrators,
    context: AccountService::Context.root
  )
end

# Special report permission for admins, needs to be manually assigned to selected admins on production
%w[
  lanalytics.report.admin
].each do |role|
  AccountService::Grant.create!(
    role: AccountService::Role.find_by(name: role),
    principal: AccountService::Group.administrators,
    context: AccountService::Context.root
  )
end

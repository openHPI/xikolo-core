# frozen_string_literal: true

# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

kevin = '00000001-3100-4444-9999-000000000001'
admin = '00000001-3100-4444-9999-000000000002'
tom   = '00000001-3100-4444-9999-000000000003'

cloud = '00000001-3300-4444-9999-000000000001'

def create_super_full_room(name, course, owner)
  full = CollabSpace.create! name:, course_id: course,
    is_open: true, owner_id: owner

  # adds the smith family
  100.times do |i|
    Membership.create! collab_space_id: full.id,
      user_id: "00000001-3100-4444-9999-000000000#{100 + i}",
      status: 'regular'
  end
  full
end

create_super_full_room('Super Full', cloud, kevin)
full2 = create_super_full_room 'Super Full kevin last member', cloud, tom
Membership.create! collab_space_id: full2.id, user_id: kevin,
  status: 'regular'

CollabSpace.create! name: "Kevin's playground", course_id: cloud,
  is_open: false, owner_id: kevin

toms = CollabSpace.create! name: "Tom's playground", course_id: cloud,
  is_open: false, owner_id: tom

# kevin wants to play
Membership.create! collab_space_id: toms.id, user_id: kevin, status: 'pending'

CollabSpace.create! name: "Admins's playground", course_id: cloud,
  is_open: false, owner_id: admin

CollabSpace.create! name: 'Open one', course_id: cloud, is_open: true,
  owner_id: kevin

100.times do |i|
  CollabSpace.create! name: "Pagination Dummy #{i}",
    course_id: cloud,
    is_open: true,
    owner_id: tom
end

#### Tatort / Peer Assessment ####

[
  ['Team Dortmund', '00000001-3100-4444-9999-000000002008', '00000001-3100-4444-9999-000000002009'], # Team Dortmund: Faber, Boenisch
  ['Team Münster', '00000001-3100-4444-9999-000000002006', '00000001-3100-4444-9999-000000002002'], # Team Muenster: Thiel, Boerne
  ['Team Berlin', '00000001-3100-4444-9999-000000002001', '00000001-3100-4444-9999-000000002010'], # Team Berlin: Ritter, Stark
  ['Team Wien', '00000001-3100-4444-9999-000000002005', '00000001-3100-4444-9999-000000002007'], # Team Wien: Fellner, Eisner
  ['Team Kiel', '00000001-3100-4444-9999-000000002003', '00000001-3100-4444-9999-000000002004'], # Team Kiel: Borowski, Brandt
  ['Admins', '00000001-3100-4444-9999-000000000002', nil], # Admins: Administrator
].each do |team_name, user1, user2|
  team_space = CollabSpace.create!(
    name: team_name,
    course_id: '00000001-3300-4444-9999-000000002001',
    is_open: false,
    kind: 'team'
  )

  team_space.memberships.create!(
    status: 'admin',
    user_id: user1
  )

  next if user2.nil?

  team_space.memberships.create!(
    status: 'admin',
    user_id: user2
  )
end

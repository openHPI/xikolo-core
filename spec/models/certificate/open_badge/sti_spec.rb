# frozen_string_literal: true

require 'spec_helper'

# We are overriding Rails' STI type column name resolution, to introduce
# symbolic names for the subtypes of OpenBadge. These names can be more easily
# mapped / changed to different classes. This functionality is tested here.
describe 'Certificate::OpenBadge: Single Table Inheritance', type: :model do
  let(:user) { create(:user) }
  let(:course) { create(:course, records_released: true) }
  let(:record) { create(:roa, course:, user:) }
  let(:template) { create(:open_badge_template, course:) }

  before do
    Stub.service(:course, build(:'course:root'))
    Stub.request(
      :course, :get, '/enrollments',
      query: hash_including({user_id: user.id, course_id: course.id})
    ).to_return Stub.json(
      build_list(
        :'course:enrollment', 1, :with_learning_evaluation,
        user_id: user.id,
        course_id: course.id
      )
    )
  end

  it "stores a symbolic name to identify a badge's concrete type" do
    badge = Certificate::OpenBadge.create!(
      record:,
      open_badge_template: template
    )

    expect(badge.type).to eq 'OpenBadge'
  end

  it 'can look up models based on symbolic names' do
    badge = Certificate::OpenBadge.create!(
      type: 'V2::OpenBadge',
      record:,
      open_badge_template: template
    )

    typed_badge = Certificate::OpenBadge.find badge.id
    expect(typed_badge).to be_a Certificate::V2::OpenBadge
  end

  it 'can not be looked up with a concrete type that does not match' do
    badge = Certificate::OpenBadge.create!(
      record:,
      open_badge_template: template
    )

    expect do
      Certificate::V2::OpenBadge.find badge.id
    end.to raise_error(ActiveRecord::RecordNotFound)
  end
end

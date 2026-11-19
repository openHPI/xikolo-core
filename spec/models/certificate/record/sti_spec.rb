# frozen_string_literal: true

require 'spec_helper'

# We are overriding Rails' STI type column name resolution, to introduce
# symbolic names for the subtypes of Record. These names can be more easily
# mapped / changed to different classes. This functionality is tested here.
describe 'Certificate::Record: Single Table Inheritance', type: :model do
  let(:user) { create(:'account_service/user') }
  let(:course) { create(:course, records_released: true) }
  let(:template) { create(:certificate_template) }

  before do
    create(
      :'course_service/enrollment',
      :with_evaluation,
      course_id: course.id,
      quantiled_user_dpoints: 90,
      user_id: user.id,
      completed: false,
      quantile: 0.9,
      deleted: false
    )
  end

  it "stores a symbolic name to identify a record's concrete type" do
    record = Certificate::ConfirmationOfParticipation.create!(
      user:,
      course:,
      template:
    )

    expect(record.type).to eq 'ConfirmationOfParticipation'
  end

  it 'can look up models based on symbolic names' do
    record = Certificate::Record.create!(
      type: 'RecordOfAchievement',
      user:,
      course:,
      template:
    )

    typed_record = Certificate::Record.find record.id
    expect(typed_record).to be_a Certificate::RecordOfAchievement
  end

  it 'can not be looked up with a concrete type that does not match' do
    record = Certificate::Record.create!(
      type: 'RecordOfAchievement',
      user:,
      course:,
      template:
    )

    expect do
      Certificate::ConfirmationOfParticipation.find record.id
    end.to raise_error(ActiveRecord::RecordNotFound)
  end
end

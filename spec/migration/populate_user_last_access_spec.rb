# frozen_string_literal: true

require 'spec_helper'
require Rails.root.join('db', 'migrate', '20230925154000_populate_user_last_access.rb')

describe PopulateUserLastAccess do
  subject(:migration) { described_class.new }

  let!(:user) { create(:user, confirmed: true) }
  let(:item) { create(:item) }
  let(:visit_date) { 1.week.ago }
  let(:visit) { create(:visit, user:, item:, updated_at: visit_date) }
  let(:enrollment) { create(:enrollment, user_id: user.id, updated_at: 2.weeks.ago) }

  it 'sets last_access to the user date' do
    expect { migration.up }.to change { user.reload.last_access }.from(nil).to(user.updated_at.to_date)
  end

  context 'with visit and enrollment' do
    before do
      visit
      enrollment
    end

    it 'sets last_access to the visit date' do
      expect { migration.up }.to change { user.reload.last_access }.from(nil).to(visit.updated_at.to_date)
    end

    context 'with older visit' do
      let(:visit_date) { 3.weeks.ago }

      it 'sets last_access to the enrollment date' do
        expect { migration.up }.to change { user.reload.last_access }.from(nil).to(enrollment.updated_at.to_date)
      end
    end
  end
end

# frozen_string_literal: true

require 'spec_helper'

describe 'Course: Enrollments: Completion: Create', type: :request do
  subject(:action) do
    post "/enrollments/#{enrollment.id}/completion",
      headers:
  end

  let(:headers) { {} }
  let(:user) { create(:'account_service/user') }
  let(:course) { create(:course, :self_paced, title: 'My course') }
  let(:enrollment) { create(:enrollment, course:, user_id: user.id) }

  context 'for anonymous user' do
    it 'redirects to login page' do
      expect(action).to redirect_to 'http://www.example.com/sessions/new'
    end
  end

  context 'for logged-in user' do
    context 'for the user\'s enrollment' do
      before do
        sign_in(user:)
      end

      it 'updates the enrollment' do
        expect { action }.to change { enrollment.reload.completed }.from(nil).to(true)
        expect(flash[:success].first).to eq 'The course was successfully marked as completed.'
        expect(action).to redirect_to dashboard_path
      end
    end

    context 'for another user\'s enrollment' do
      let(:other_user) { create(:'account_service/user') }

      before do
        sign_in(user: other_user)
      end

      it 'does not update the enrollment' do
        expect { action }.not_to change(enrollment, :completed).from(nil)
        expect(action).to redirect_to root_url
      end
    end
  end
end

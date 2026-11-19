# frozen_string_literal: true

require 'spec_helper'

describe DashboardController, type: :controller do
  subject { request }

  let(:user) { create(:'account_service/user') }

  describe '#dashboard' do
    let(:request) { get :dashboard }

    context 'anonymous' do
      it 'redirects if not logged in' do
        expect(request.status).to eq 302
      end

      context 'with external login page configured' do
        before do
          xi_config <<~YML
            portal_mode:
              external_login:
                enabled: true
                url: https://example.com/signin
          YML
        end

        it 'redirects to the external login page' do
          expect(request).to redirect_to 'https://example.com/signin'
        end
      end
    end

    context 'with user' do
      let(:enrollments) { [] }
      let(:next_dates) { [] }

      before do
        Stub.request(
          :course, :get, '/next_dates',
          query: {user_id: user.id}
        ).to_return Stub.json(next_dates)

        sign_in user: user
      end

      its(:status) { is_expected.to eq 200 }

      context 'assign' do
        subject { request; assigns }

        it { is_expected.to include 'next_dates' }
      end
    end
  end

  describe '#documents' do
    let(:request) { get :documents }
    let(:course_id) { SecureRandom.uuid }

    context 'anonymous' do
      it 'redirects if not logged in' do
        expect(request.status).to eq 302
      end
    end

    context 'with user' do
      before { sign_in user: user }

      context 'without documents' do
        its(:status) { is_expected.to eq 200 }

        context 'assign' do
          subject { request; assigns }

          it { is_expected.to include 'documents' }
        end
      end

      context 'with documents' do
        let(:course) { create('course_service/course', id: course_id, records_released: true) }

        before { create('course_service/enrollment', :with_evaluation, user:, course:) }

        its(:status) { is_expected.to eq 200 }

        context 'assign' do
          subject { request; assigns }

          it { is_expected.to include 'documents' }
          its([:documents]) { is_expected.to have(1).item }
        end
      end
    end
  end
end

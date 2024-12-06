# frozen_string_literal: true

require 'spec_helper'

describe DashboardController, type: :controller do
  subject { request }

  let(:user_id) { '00000001-3100-4444-9999-000000000001' }

  before do
    Stub.service(:course, build(:'course:root'))
  end

  describe '#dashboard' do
    let(:request) { get :dashboard }

    context 'anonymous' do
      let(:user_id) { nil }

      it 'redirects if not loged in' do
        expect(request.status).to eq 302
      end
    end

    context 'with user' do
      let(:enrollments) { [] }
      let(:my_promoted) { [] }
      let(:next_dates) { [] }

      before do
        Stub.request(
          :course, :get, '/enrollments',
          query: hash_including(user_id:, learning_evaluation: 'true')
        ).to_return Stub.json(enrollments)
        Stub.request(
          :course, :get, '/courses',
          query: {promoted_for: user_id}
        ).to_return Stub.json(my_promoted)
        Stub.request(
          :course, :get, '/next_dates',
          query: {user_id:}
        ).to_return Stub.json(next_dates)
        Stub.request(
          :account, :post, '/tokens',
          body: hash_including(user_id:)
        ).to_return Stub.json({token: 'abc'})

        stub_user id: user_id
      end

      its(:status) { is_expected.to eq 200 }

      context 'assign' do
        subject { request; assigns }

        it { is_expected.to include 'my_promoted' }
        it { is_expected.to include 'next_dates' }
      end
    end
  end

  describe '#documents' do
    let(:request) { get :documents }
    let(:course_id) { SecureRandom.uuid }

    context 'anonymous' do
      let(:user_id) { nil }

      it 'redirects if not logged in' do
        expect(request.status).to eq 302
      end
    end

    context 'with user' do
      before { stub_user id: user_id }

      context 'without documents' do
        let(:enrollments) do
          [
            {
              certificates: {confirmation_of_participation: false},
              course_id:,
            },
          ]
        end

        before do
          Stub.request(
            :course, :get, '/enrollments',
            query: {user_id:, learning_evaluation: 'true', deleted: 'true'}
          ).to_return Stub.json(enrollments)

          Stub.request(
            :account, :get, "/users/#{user_id}/preferences"
          ).to_return Stub.json({properties: {}})
        end

        its(:status) { is_expected.to eq 200 }

        context 'assign' do
          subject { request; assigns }

          it { is_expected.to include 'documents' }
        end
      end

      context 'with documents' do
        let(:enrollments) do
          [
            {
              certificates: {confirmation_of_participation: true},
              course_id:,
            },
          ]
        end

        before do
          Stub.service(:course, course_url: '/courses/{id}')

          Stub.request(
            :course, :get, '/enrollments',
            query: {user_id:, learning_evaluation: 'true', deleted: 'true'}
          ).to_return Stub.json(enrollments)

          Stub.request(
            :course, :get, "/courses/#{course_id}"
          ).to_return Stub.json({
            id: course_id,
            title: 'Course',
            code: 'code',
          })

          Stub.request(
            :account, :get, "/users/#{user_id}/preferences"
          ).to_return Stub.json({properties: {}})
        end

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

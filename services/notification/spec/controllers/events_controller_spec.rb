# frozen_string_literal: true

require 'spec_helper'

describe EventsController, type: :controller do
  let(:json) { JSON.parse response.body }
  let(:params) { {} }

  describe 'GET index' do
    subject(:action) { get :index, params: }

    let!(:event) { create(:event) }

    it { is_expected.to have_http_status :ok }

    it 'has items' do
      action
      expect(json).to have(1).items
    end

    context 'with pagination' do
      let(:params) { super().merge(page: 10) }

      it 'returns no results' do
        action
        expect(json).to have(0).items
      end
    end

    context 'with locale' do
      let(:params) { super().merge(locale: 'de') }

      it 'has a localized title' do
        action
        expect(json.first['title']).to eq 'Neue Nachricht: katze'
      end
    end

    describe 'collab space' do
      before { create(:event, collab_space_id: 'bb88f2f8-d1a5-40de-be18-496c6b576fe2') }

      context 'no param' do
        it 'shows all items' do
          action
          expect(json).to have(2).items
        end
      end

      context 'with param' do
        let(:params) { super().merge(only_collab_space_related: 'true') }

        it 'has only one item' do
          action
          expect(json).to have(1).items
        end
      end
    end

    context 'for a user' do
      let!(:event) { create(:event, :with_notifications, notify_user: [user_id]) }
      let(:params) { super().merge(user_id:) }
      let(:user_id) { generate(:user_id) }

      context 'with public, non-public, and events with notifications' do
        let!(:public_events) { create_list(:event, 5) }
        let!(:notification_events) { create_list(:event, 5, :with_notifications, notify_user: [user_id, generate(:user_id)]) }

        before do
          # Five more private events that should not be listed
          create_list(:event, 5, :not_public)
        end

        it 'returns the right events' do
          action
          ids = json.pluck('id')
          expected_ids = public_events.map(&:id) + notification_events.map(&:id) + [event.id]

          expect(ids).to match_array expected_ids
        end
      end
    end

    context 'with course_id' do
      let(:params) { super().merge(course_id:) }
      let(:course_id) { SecureRandom.uuid }
      let(:course_id2) { SecureRandom.uuid }
      let(:event) { create(:event, course_id:) }

      before do
        # Another event in a different course
        create(:event, course_id: course_id2)
      end

      it 'finds the item' do
        action
        expect(json).to have(1).items
      end

      context 'with list of course_ids' do
        let(:params) { super().merge(course_id: "#{course_id}/#{course_id2}") }

        it 'finds the items' do
          action
          expect(json).to have(2).items
        end
      end
    end
  end

  describe 'POST create' do
    subject(:action) { post :create, params: }

    let(:params) do
      {
        key: 'foobar',
        payload: {foo: 'bar'},
        public: true,
        course_id: SecureRandom.uuid,
        collab_space_id: SecureRandom.uuid,
        link: 'http',
      }
    end

    before { Sidekiq::Testing.fake! }

    it 'creates a new event' do
      expect { action }.to change(Event, :count).by(1)
    end

    it 'schedules a job to create notifications for the subscribers' do
      expect { action }.to change(CreateNotificationsWorker.jobs, :size).by(1)
    end
  end
end

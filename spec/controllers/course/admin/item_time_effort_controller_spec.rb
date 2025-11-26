# frozen_string_literal: true

require 'spec_helper'

describe Course::Admin::ItemTimeEffortController, type: :controller do
  let(:user_id) { '00000001-3100-4444-9999-000000000001' }
  let(:course_id) { '00000001-3300-4444-9999-000000000001' }
  let(:section_id) { '00000001-3300-5555-9999-000000000001' }
  let(:item_id) { '00000001-3300-6666-9999-000000000001' }
  let(:params) { {course_id:, section_id:, item_id:} }
  let(:permissions) { ['course.content.access', 'course.content.edit'] }
  let(:course) { build(:'course:course') }
  let(:time_effort_item) do
    {
      'id' => params[:item_id],
      'time_effort' => 20,
      'calculated_time_effort' => 30,
      'time_effort_overwritten' => false,
      'overwritten_time_effort_url' =>  stub_url(:timeeffort, "/items/#{params[:item_id]}/overwritten_time_effort"),
    }
  end
  let(:login_user) do
    stub_user id: user_id, language: 'en', permissions:
  end
  let(:item_stub_response) { Stub.json(time_effort_item) }

  before do
    Stub.service(:account, build(:'account:root'))
    Stub.service(:course, build(:'course:root'))
    Stub.service(:timeeffort, build(:'timeeffort:root'))
    Stub.request(:course, :get, "/courses/#{params[:course_id]}").to_return Stub.json(course)
    Stub.request(:timeeffort, :get, "/timeeffort_service/items/#{params[:item_id]}").to_return item_stub_response
  end

  describe 'GET #show' do
    subject(:action) { get :show, params: }

    context 'with user logged in' do
      before { login_user }

      context 'w/o client error' do
        it 'responds with the status information' do
          expect(parse_json(action.body)).to include json \
            'time_effort' => time_effort_item['time_effort'],
            'calculated_time_effort'  => time_effort_item['calculated_time_effort'],
            'time_effort_overwritten' => time_effort_item['time_effort_overwritten']
        end

        it 'responds with 200 Ok' do
          expect(action.status).to eq 200
        end

        context 'w/ missing item' do
          let(:item_stub_response) { Stub.json({}, status: 404) }

          it 'responds with 422 Unprocessable Entity' do
            expect(action.status).to eq 422
          end
        end
      end

      context 'w/ client error' do
        let(:item_stub_response) { Stub.response(status: 422) }

        it 'responds with 422 Unprocessable Entity' do
          expect(action.status).to eq 422
        end
      end

      context 'w/o permissions' do
        let(:permissions) { [] }

        it 'responds with 403 Forbidden' do
          expect(action.status).to eq 403
        end
      end
    end

    context 'with user not logged in' do
      it 'responds with 403 Forbidden' do
        expect(action.status).to eq 403
      end
    end
  end

  describe 'PUT #update' do
    subject(:action) { post :update, params: }

    let(:params) { super().merge(time_effort: time_effort_item['time_effort']) }

    context 'with user logged in' do
      let(:item_update_stub_response) { Stub.response(status: 204) }
      let!(:item_update_stub) do
        Stub.request(
          :timeeffort,
          :put,
          "/items/#{params[:item_id]}/overwritten_time_effort",
          body: {time_effort: params[:time_effort].to_s}
        ).to_return item_update_stub_response
      end

      before { login_user }

      it 'updates the item' do
        action
        expect(item_update_stub).to have_been_requested
      end

      context 'w/o client error' do
        it 'responds with 204 No Content' do
          expect(action.status).to eq 204
        end
      end

      context 'w/ client error' do
        let(:item_update_stub_response) { Stub.response(status: 422) }

        it 'responds with 422 Unprocessable Entity' do
          expect(action.status).to eq 422
        end
      end

      context 'w/o permissions' do
        let(:permissions) { [] }

        it 'responds with 403 Forbidden' do
          expect(action.status).to eq 403
        end
      end
    end

    context 'with user not logged in' do
      it 'responds with 403 Forbidden' do
        expect(action.status).to eq 403
      end
    end
  end

  describe 'DELETE #destroy' do
    subject(:action) { delete :destroy, params: }

    context 'with user logged in' do
      let(:item_delete_stub_response) { Stub.json(time_effort_item) }
      let!(:item_delete_stub) do
        Stub.request(
          :timeeffort,
          :delete,
          "/items/#{params[:item_id]}/overwritten_time_effort"
        ).to_return item_delete_stub_response
      end

      before { login_user }

      it 'deletes the time effort for the item' do
        action
        expect(item_delete_stub).to have_been_requested
      end

      context 'w/o client error' do
        it 'responds with the status information' do
          expect(parse_json(action.body)).to include json \
            'time_effort' => time_effort_item['time_effort'],
            'calculated_time_effort'  => time_effort_item['calculated_time_effort'],
            'time_effort_overwritten' => time_effort_item['time_effort_overwritten']
        end

        it 'responds with the 200 OK' do
          expect(action.status).to eq 200
        end
      end

      context 'w/ client error' do
        let(:item_delete_stub_response) { Stub.response(status: 422) }

        it 'responds with 422 Unprocessable Entity' do
          expect(action.status).to eq 422
        end
      end

      context 'w/o permissions' do
        let(:permissions) { [] }

        it 'responds with 403 Forbidden' do
          expect(action.status).to eq 403
        end
      end
    end

    context 'with user not logged in' do
      it 'responds with 403 Forbidden' do
        expect(action.status).to eq 403
      end
    end
  end
end

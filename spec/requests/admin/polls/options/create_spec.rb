# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Admin: Poll: Options: Create', type: :request do
  let(:create_option) { post "/admin/polls/#{poll.id}/options", params:, headers: }
  let(:headers) { {} }
  let(:poll) { create(:poll, :current, option_count: 0) }
  let(:params) { {text: 'New option'} }

  # NOTE: Manually create the poll option as the factory would falsify
  # the position attribute (since it is setting the position attribute to n,
  # which depends on the execution order).
  before do
    poll.options.create!(text: 'Option 1')
  end

  context 'with permissions' do
    let(:headers) { {Authorization: "Xikolo-Session session_id=#{stub_session_id}"} }
    let(:permissions) { %w[helpdesk.polls.manage] }

    before { stub_user_request permissions: }

    context 'when the poll has not yet started' do
      let(:poll) { create(:poll, :future, option_count: 0) }

      it 'adds a new option to the poll' do
        expect { create_option }.to change(Poll::Option, :count).from(1).to(2)
        expect(poll.reload.options).to match [
          an_object_having_attributes(text: 'Option 1', position: 1),
          an_object_having_attributes(text: params[:text], position: 2),
        ]
      end
    end

    context 'when the poll has already started' do
      let(:poll) { create(:poll, :current, option_count: 0) }

      it 'does not add a new option to the poll' do
        expect { create_option }.not_to change(Poll::Option, :count).from(1)
        expect(response).to have_http_status :unprocessable_entity
      end
    end
  end

  context 'without permissions' do
    it 'responds with 403 Forbidden' do
      create_option
      expect(response).to have_http_status :forbidden
    end
  end
end

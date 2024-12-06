# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Admin: Poll: Options: Destroy', type: :request do
  let(:destroy_option) { delete "/admin/polls/#{poll.id}/options/#{option_1.id}", params:, headers: }
  let(:headers) { {} }
  let(:poll) { create(:poll, :current, option_count: 0) }
  let(:params) { {text: 'New option'} }

  # NOTE: Manually create the poll options as the factory would falsify
  # the position attribute (since it is setting the position attribute to n,
  # which depends on the execution order).
  let(:option_1) { poll.options.create!(text: 'Option 1') }

  before do
    option_1
    poll.options.create!(text: 'Option 2')
  end

  context 'with permissions' do
    let(:headers) { {Authorization: "Xikolo-Session session_id=#{stub_session_id}"} }
    let(:permissions) { %w[helpdesk.polls.manage] }

    before { stub_user_request permissions: }

    context 'when the poll has not yet started' do
      let(:poll) { create(:poll, :future, option_count: 0) }

      it 'removes the option' do
        expect { destroy_option }.to change(Poll::Option, :count).from(2).to(1)
        # NOTE: The option positions are not cleaned up.
        expect(poll.reload.options).to match [
          an_object_having_attributes(text: 'Option 2', position: 2),
        ]
      end
    end

    context 'when the poll has already started' do
      let(:poll) { create(:poll, :current, option_count: 0) }

      it 'does not remove the option' do
        expect { destroy_option }.not_to change(Poll::Option, :count).from(2)
        expect(response).to have_http_status :unprocessable_entity
      end
    end
  end

  context 'without permissions' do
    it 'responds with 403 Forbidden' do
      destroy_option
      expect(response).to have_http_status :forbidden
    end
  end
end

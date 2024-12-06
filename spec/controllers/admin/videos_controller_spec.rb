# frozen_string_literal: true

require 'spec_helper'

describe Admin::VideosController, type: :controller do
  let(:user_id) { '00000001-3100-4444-9999-000000000001' }
  let(:permissions) { [] }
  let(:user) do
    {id: user_id,
     display_name: 'John Smith',
     permissions:}
  end

  describe '#index' do
    subject(:action) { get :index }

    before { stub_user(**user) }

    context 'with no params' do
      let(:permissions) { super().push('video.video.manage') }

      it 'answers with a page' do
        action
        expect(response).to have_http_status :ok
      end
    end

    context 'as user' do
      it 'redirects to the start page' do
        action
        expect(response).to redirect_to '/'
      end
    end
  end
end

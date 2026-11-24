# frozen_string_literal: true

require 'spec_helper'

describe VideoPresenter, type: :presenter do
  subject(:presenter) { described_class.new(video:, user:, course:) }

  let(:course) { create(:course) }
  let(:session) { create(:'account_service/session') }
  let(:user) { CurrentUser::User.new(session:, context_id: 'root') }

  describe '#player' do
    context 'with a single bunny stream' do
      let(:video) { create(:video, pip_stream: create(:stream, :bunny)) }

      before do
        create(:item, section: create(:section, course:), content: video)
      end

      it 'builds the bunny player' do
        expect(presenter.player).to be_a(Video::BunnyPlayer)
      end
    end

    context 'with a single vimeo stream' do
      let(:video) { create(:video, pip_stream: create(:stream, :vimeo)) }

      it 'builds the vimeo player' do
        expect(presenter.player).to be_a(Video::VideoPlayer)
      end
    end

    context 'with a dual vimeo stream' do
      let(:video) do
        create(:video, pip_stream: nil, lecturer_stream: create(:stream, :vimeo), slides_stream: create(:stream, :vimeo))
      end

      it 'builds the vimeo player' do
        expect(presenter.player).to be_a(Video::VideoPlayer)
      end
    end
  end
end

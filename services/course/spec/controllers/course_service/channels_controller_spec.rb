# frozen_string_literal: true

require 'spec_helper'

describe CourseService::ChannelsController, type: :controller do
  include_context 'course_service API controller'
  let(:channel) { create(:'course_service/channel') }
  let(:archived_channel) { create(:'course_service/channel', archived: true) }
  let(:affiliated_channel) { create(:'course_service/channel', affiliated: true) }
  let(:json) { JSON.parse response.body }
  let(:default_params) { {format: 'json'} }
  let(:params) { {} }

  describe "GET 'index'" do
    let(:action) { -> { get :index, params: } }

    before { channel; action.call }

    it 'returns http success' do
      expect(response).to have_http_status :ok
    end

    it 'returns a list' do
      expect(json).to have(1).item
    end

    it 'returns only non-archived channels' do
      archived_channel
      get :index
      expect(json).to have(1).item
    end

    it 'returns only non-affiliated channels' do
      affiliated_channel
      get :index
      expect(json).to have(1).item
    end

    it 'answers with channel resources' do
      expect(json[0]).to eq CourseService::ChannelDecorator.new(channel).as_json(api_version: 1).stringify_keys
    end

    context 'only public channels' do
      let(:params) { {public: 'true'} }

      before do
        create_list(:'course_service/channel', 2, public: false)
        action.call
      end

      it 'returns only public channels' do
        expect(json).to have(1).item
      end
    end

    context 'with affiliated channels' do
      let(:params) { {affiliated: 'true'} }

      before do
        affiliated_channel
        action.call
      end

      it 'does not return affiliated channel' do
        expect(json).to have(1).item
        expect(json[0]['id']).to eq channel.id
      end
    end
  end

  describe "GET 'show'" do
    let(:channel_id) { channel.id }
    let(:action) { -> { get :show, params: {id: channel_id} } }

    before { action.call }

    it 'returns http success' do
      expect(response).to have_http_status :ok
    end

    it 'answers with a channel resource' do
      expect(json).to eq CourseService::ChannelDecorator.new(channel).as_json(api_version: 1).stringify_keys
    end

    context 'query by channel code' do
      let(:channel_id) { channel.code }

      it 'returns http success' do
        expect(response).to have_http_status :ok
      end

      it 'answers with a channel resource' do
        expect(json).to eq CourseService::ChannelDecorator.new(channel).as_json(api_version: 1).stringify_keys
      end
    end
  end

  describe "POST 'create'" do
    let(:params) { attributes_for(:'course_service/channel') }
    let(:action) { -> { post :create, params: } }

    it 'creates new channel' do
      expect { action.call }.to change(CourseService::Channel, :count).from(0).to(1)
    end

    it 'responds with a 200' do
      action.call
      expect(response).to have_http_status :created
    end

    context 'full record' do
      let!(:params) { attributes_for(:'course_service/channel', :full_blown) }

      before { action.call }

      it 'has the correct data' do
        expect(json['code']).not_to be_nil
        expect(json['code']).to eq params[:code]
        expect(json['title_translations']['en']).to eq params[:title_translations]['en']
        expect(json['title_translations']['en']).not_to be_nil
        expect(json['description']['en']).to eq params[:description][:en]
        expect(json['description']).not_to be_nil
        expect(json['stage_statement']).to eq params[:stage_statement]
        expect(json['stage_statement']).not_to be_nil
        expect(json['info_link']).to eq params[:info_link]
        expect(json['info_link']).not_to be_nil
      end
    end

    context 'with invalid channel code' do
      let(:params) { {code: '', title_translations: {'en' => 'Channel X', 'de' => 'Channel X'}} }

      it 'responds with 422 Unprocessable Entity on invalid data' do
        action.call
        expect(response).to have_http_status :unprocessable_content
      end
    end

    context 'with double channel code' do
      before { channel }

      let(:params) { {code: channel.code, title_translations: {'en' => 'Channel X', 'de' => 'Channel X'}} }

      it 'responds with 422 Unprocessable Entity on taken channel code' do
        action.call
        expect(response).to have_http_status :unprocessable_content
      end
    end
  end

  describe "PUT 'update'" do
    before { channel }

    let(:stage_statement) { 'Welcome to the channel' }
    let(:action) { -> { put :update, params: } }
    let(:params) { {id: channel.id, stage_statement:} }

    describe 'response' do
      subject { response }

      before { action.call }

      its(:status) { is_expected.to eq 204 }
    end

    describe 'record' do
      subject { channel.reload }

      before { action.call }

      its(:stage_statement) { is_expected.to eq stage_statement }
    end
  end

  describe "DELETE 'destroy'" do
    before { channel }

    let(:action) { -> { delete :destroy, params: {id: channel.id} } }

    describe 'response' do
      subject { response }

      before { action.call }

      its(:status) { is_expected.to eq 204 }
    end

    describe 'record' do
      subject { channel.reload }

      it 'deletes the channel' do
        expect { action.call }.to change(CourseService::Channel, :count).from(1).to(0)
      end
    end
  end
end

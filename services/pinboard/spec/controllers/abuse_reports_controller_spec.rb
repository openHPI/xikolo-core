# frozen_string_literal: true

require 'spec_helper'

describe AbuseReportsController, type: :controller do
  let(:json) { JSON.parse response.body }
  let(:default_params) { {format: 'json'} }
  let(:reportable) { create(:'pinboard_service/question') }
  let(:report) { create(:'pinboard_service/abuse_report', reportable:) }

  describe 'index' do
    subject { action.call; json }

    before { create_list(:'pinboard_service/abuse_report', 3) }

    let(:action) { -> { get :index, params: } }
    let(:params) { {} }

    it { is_expected.to have(3).items }

    context 'with course_id' do
      let(:report) { create(:'pinboard_service/abuse_report', course_id: SecureRandom.uuid) }
      let(:params) { super().merge! course_id: report.course_id }

      it { is_expected.to have(1).item }
    end

    context 'with open flag' do
      before { report }

      let(:params) { super().merge! open: true }

      it { is_expected.to have(4).items }

      context 'with reviewed reportable' do
        before { reportable.review! }

        it { is_expected.to have(3).items }
      end
    end
  end

  describe 'show' do
    before { get :show, params: {id: report.id} }

    it 'returns http success' do
      expect(response).to have_http_status :ok
    end
  end

  describe 'create' do
    shared_examples_for 'invalid input' do
      it 'returns a 404' do
        action.call
        expect(response).to have_http_status :not_found
      end

      it 'does not create a report' do
        expect { action.call }.not_to change(AbuseReport, :count)
      end
    end

    let(:params) { attributes_for(:'pinboard_service/abuse_report', reportable_id: reportable.id) }
    let(:action) { -> { post :create, params: } }

    it 'returns http created' do
      action.call
      expect(response).to have_http_status :created
    end

    it 'creates a report' do
      expect { action.call }.to change(AbuseReport, :count).by 1
    end

    context 'with incorrect reportable_id' do
      let(:params) { super().merge reportable_id: 'foo' }

      it_behaves_like 'invalid input'
    end

    context 'with incorrect reportable_type' do
      let(:params) { super().merge reportable_type: 'test' }

      it_behaves_like 'invalid input'
    end
  end
end

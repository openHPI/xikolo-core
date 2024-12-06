# frozen_string_literal: true

require 'spec_helper'

describe API::FeaturesController, type: :controller do
  let(:owner) { create(:user) }
  let!(:features) { create_list(:feature, 2, owner:) }

  describe '#index' do
    context 'with user' do
      subject(:response) { get :index, params: {user_id: owner} }

      it { is_expected.to have_http_status :ok }

      describe 'JSON' do
        subject(:json) { JSON.parse(response.body) }

        it 'is the users feature map' do
          expect(json).to eq(
            features.to_h {|f| [f.name, f.value] }.merge(
              'account.profile.mandatory_completed' => 'true'
            )
          )
        end
      end
    end

    context 'with invalid user ID' do
      subject(:response) { get :index, params: {user_id: 'invalid'} }

      it { is_expected.to have_http_status :not_found }
    end

    context 'with group' do
      subject(:response) { get :index, params: {group_id: owner} }

      let(:owner) { create(:group) }

      it { is_expected.to have_http_status :ok }

      describe 'JSON' do
        subject(:json) { JSON.parse(response.body) }

        it { expect(json.size).to eq 2 }

        it 'is the users feature map' do
          expect(json).to eq features.to_h {|f| [f.name, f.value] }
        end
      end
    end

    context 'with invalid group ID' do
      subject(:response) { get :index, params: {group_id: 'group.invalid'} }

      it { is_expected.to have_http_status :not_found }
    end
  end
end

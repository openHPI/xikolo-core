# frozen_string_literal: true

require 'spec_helper'

describe 'Social User Search', type: :request do
  let(:api) { Restify.new(:test).get.value! }

  let!(:users) do
    [
      create(:user, full_name: 'Adolf Hubel', display_name: nil),
      create(:user, full_name: 'John Smith', display_name: nil),
      create(:user, full_name: 'Bill Johnson', display_name: nil),
      create(:user, full_name: 'Kevin Zuhause', display_name: 'Allein'),
    ]
  end

  describe 'filter by email' do
    subject(:resource) { api.rel(:users).get(search: users[0].email).value! }

    it { expect(resource.size).to eq 1 }

    context 'when disallowed by setting' do
      before do
        users[0].update! preferences: users[0].preferences.merge('social.allow_detection_via_email' => false)
      end

      it { expect(resource.size).to eq 0 }
    end
  end

  describe 'filter by real name' do
    subject(:resource) { api.rel(:users).get(search: 'john').value! }

    it { expect(resource.size).to eq 2 }

    it 'matches first name' do
      expect(resource.each.pluck('id')).to include users[1].id
    end

    it 'matches last name' do
      expect(resource.each.pluck('id')).to include users[2].id
    end

    context 'when disallowed by setting' do
      before do
        users[1].update! preferences: users[1].preferences.merge('social.allow_detection_via_name' => false)
      end

      it { expect(resource.pluck('id')).to eq [users[2].id] }
    end
  end

  describe 'filter by display name' do
    subject(:resource) { api.rel(:users).get(search: 'allei').value! }

    it { expect(resource.size).to eq 1 }

    it 'matches display name' do
      expect(resource.each.pluck('id')).to include users[3].id
    end

    context 'when disallowed by setting' do
      before do
        users[3].update! preferences: users[3].preferences.merge('social.allow_detection_via_display_name' => false)
      end

      it { expect(resource.size).to eq 0 }
    end
  end
end

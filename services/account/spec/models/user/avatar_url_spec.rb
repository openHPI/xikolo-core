# frozen_string_literal: true

require 'spec_helper'

describe User, '#avatar_url', type: :model do
  subject(:user) { create(:user, attributes) }

  let(:attributes) { {} }

  describe '#avatar_url' do
    subject(:avatar_url) { user.avatar_url }

    context 'without avatar URI' do
      it { is_expected.to be_nil }
    end

    context 'with avatar URI' do
      let(:attributes) { {avatar_uri: 's3://xikolo-avatars/users/test.png'} }

      it do
        expect(avatar_url).to eq \
          'http://s3.xikolo.de/xikolo-avatars/users/test.png'
      end
    end
  end
end

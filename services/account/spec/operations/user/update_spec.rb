# frozen_string_literal: true

require 'spec_helper'

describe User::Update, type: :operation do
  subject(:operation) { described_class.new(user, attributes) }

  let!(:user) { create(:user) }
  let(:attributes) { {} }

  describe '(external avatar URL)' do
    let(:attributes) do
      {avatar_uri: 'https://external.example.com/profil.jpg'}
    end

    it 'stores the external avatar URL' do
      expect { operation.call }.to change { user.reload.avatar_uri }
        .from(nil)
        .to(attributes[:avatar_uri])
    end

    context 'deleting an existing avatar' do
      let(:user) do
        create(:user, avatar_uri: 'https://external.example.com/profil_old.jpg')
      end
      let(:attributes) { {avatar_uri: nil} }

      it 'deletes the avatar URI' do
        expect { operation.call }.to change { user.reload.avatar_uri }
          .from('https://external.example.com/profil_old.jpg')
          .to(nil)
      end
    end

    context 'with no user avatar params provided at all' do
      let(:user) do
        create(:user, avatar_uri: 'https://external.example.com/profil_old.jpg')
      end
      let(:attributes) { {display_name: 'Jane Doe'} }

      it 'does not delete the avatar URI' do
        expect { operation.call }.not_to change { user.reload.avatar_uri }
      end
    end
  end
end

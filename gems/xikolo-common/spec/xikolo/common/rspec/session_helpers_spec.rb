# frozen_string_literal: true

require 'xikolo/common/rspec'

RSpec.describe 'Session helpers' do
  before do
    Stub.service(
      :account,
      session_url: '/sessions/{id}{?embed,context}'
    )
  end

  describe '#setup_session' do
    subject { setup_session user_id }

    context 'with a real user ID' do
      let(:user_id) { SecureRandom.uuid }

      describe 'a CurrentUser object using the stub' do
        subject do
          Xikolo::Common::Auth::CurrentUser.from_session(
            Xikolo.api(:account).value!.rel(:session).get(
              id: super(), context: 'root', embed: 'user,permissions,features'
            ).value!
          )
        end

        it { is_expected.to be_authenticated }
      end
    end

    context 'requesting an anonymous session' do
      let(:user_id) { nil }

      describe 'a CurrentUser object using the stub' do
        subject do
          super()
          Xikolo::Common::Auth::CurrentUser.from_session(
            Xikolo.api(:account).value!.rel(:session).get(
              id: 'anonymous', context: 'root', embed: 'user,permissions,features'
            ).value!
          )
        end

        it { is_expected.to be_anonymous }
      end
    end
  end
end

# frozen_string_literal: true

require 'spec_helper'

describe 'Account: Treatments: Consent', type: :request do
  subject(:consent) { post '/treatments', params: }

  let(:user) { create(:'account_service/user') }

  before do
    sign_in(user:)
    create(:'account_service/treatment', name: 'data_processing')
    create(:'account_service/treatment', name: 'tracking')
  end

  def stored_consents
    user.consents.map {|c| [c.treatment.name, c.value] }
  end

  context 'to all treatments' do
    let(:params) { {consent: %w[data_processing tracking]} }

    it 'stores all consents' do
      consent

      expect(stored_consents)
        .to contain_exactly(['data_processing', true], ['tracking', true])
    end
  end

  context 'to some treatments' do
    let(:params) { {consent: %w[data_processing]} }

    it 'stores consents and declines' do
      consent

      expect(stored_consents)
        .to contain_exactly(['data_processing', true], ['tracking', false])
    end
  end

  context 'to none of the treatments' do
    let(:params) { {consent: nil} }

    it 'stores all declines' do
      consent

      expect(stored_consents)
        .to contain_exactly(['data_processing', false], ['tracking', false])
    end
  end

  context 'with a required treatment' do
    before do
      AccountService::Treatment.find_by!(name: 'data_processing').update!(required: true)
    end

    context 'when the required consent is given' do
      let(:params) { {consent: %w[data_processing]} }

      it 'stores all consents' do
        consent

        expect(stored_consents)
          .to contain_exactly(['data_processing', true], ['tracking', false])
      end
    end

    context 'when the required consent is missing' do
      let(:params) { {consent: %w[tracking]} }

      it 'stores nothing and sends the user back to the form' do
        consent

        expect(stored_consents).to be_empty
        expect(response).to redirect_to '/treatments'
        expect(flash[:error]).to include 'Sorry, an error occurred when updating your consents. ' \
                                         'Please try again or get in touch with our helpdesk.'
      end
    end
  end
end

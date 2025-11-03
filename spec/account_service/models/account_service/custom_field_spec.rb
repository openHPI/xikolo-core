# frozen_string_literal: true

require 'spec_helper'

describe AccountService::CustomField, type: :model do
  subject { value }

  let(:attrs) { {} }
  let(:field) { create(:'account_service/custom_text_field', attrs) }

  describe '#destroy' do
    subject(:destroy) { field.destroy! }

    context 'with values' do
      before do
        field.update_values(create(:'account_service/user'), ['text'])
        field.update_values(create(:'account_service/user'), ['text'])
        field.update_values(create(:'account_service/user'), ['text'])
      end

      it 'destroys value records' do
        expect { destroy }.to change(AccountService::CustomFieldValue, :count).from(3).to(0)
      end
    end
  end

  describe '#update' do
    before { field.update!(params) }

    let(:params) { {title: 'New Name'} }

    describe 'AccountService::ProfileCompletion::UpdateAllJob' do
      context 'when `required` changed' do
        let(:params) { {required: true} }

        it 'invokes job' do
          expect(AccountService::ProfileCompletion::UpdateAllJob).to have_been_enqueued
        end
      end

      context 'when `required` did not changed' do
        it 'invokes job' do
          expect(AccountService::ProfileCompletion::UpdateAllJob).not_to have_been_enqueued
        end
      end
    end
  end
end

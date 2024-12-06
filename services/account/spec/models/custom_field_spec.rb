# frozen_string_literal: true

require 'spec_helper'

describe CustomField, type: :model do
  subject { value }

  let(:attrs) { {} }
  let(:field) { create(:custom_text_field, attrs) }

  describe '#destroy' do
    subject(:destroy) { field.destroy! }

    context 'with values' do
      before do
        field.update_values(create(:user), ['text'])
        field.update_values(create(:user), ['text'])
        field.update_values(create(:user), ['text'])
      end

      it 'destroys value records' do
        expect { destroy }.to change(CustomFieldValue, :count).from(3).to(0)
      end
    end
  end

  describe '#update' do
    before { field.update!(params) }

    let(:params) { {title: 'New Name'} }

    describe 'ProfileCompletion::UpdateAllJob' do
      context 'when `required` changed' do
        let(:params) { {required: true} }

        it 'invokes job' do
          expect(ProfileCompletion::UpdateAllJob).to have_been_enqueued
        end
      end

      context 'when `required` did not changed' do
        it 'invokes job' do
          expect(ProfileCompletion::UpdateAllJob).not_to have_been_enqueued
        end
      end
    end
  end
end

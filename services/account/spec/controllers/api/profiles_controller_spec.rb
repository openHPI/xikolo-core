# frozen_string_literal: true

require 'spec_helper'
require 'xikolo/validators/base'

describe API::ProfilesController, type: :controller do
  let(:user) { create(:user) }
  let(:json) { JSON.parse(response.body) }

  describe '#show' do
    subject(:response) { get :show, params: {user_id: user.id} }

    let!(:profession_field) do
      create(:custom_text_field,
        name: :profession,
        title: 'Profession')
    end

    let!(:background_field) do
      create(:custom_select_field,
        name: :background,
        title: 'Background in IT',
        values: ['None', 'Up to 1 year', 'Up to 5 years',
                 'Up to 10 years', 'More than 10 years'],
        default_values: ['None'])
    end

    before do
      create(:custom_field_value,
        custom_field: profession_field,
        context: user,
        values: ['Professor'])
    end

    it { is_expected.to have_http_status :ok }

    describe 'JSON' do
      subject(:json) { JSON.parse(response.body) }

      it 'fields should not be empty' do
        expect(json['fields']).not_to be_empty
      end

      it 'has array values' do
        expect(json['fields']).to all match hash_including('values' => Array)
      end

      it 'serializes fields correctly, combined with user responses' do
        expect(json['fields']).to contain_exactly(hash_including(
          'name' => 'profession',
          'title' => {'en' => 'Profession'},
          'type' => 'CustomTextField',
          'available_values' => [],
          'default_values' => [''],
          'required' => false,
          'values' => ['Professor'] # What the user answered
        ), hash_including(
          'name' => 'background',
          'title' => {'en' => 'Background in IT'},
          'type' => 'CustomSelectField',
          'available_values' => ['None', 'Up to 1 year', 'Up to 5 years',
                                 'Up to 10 years', 'More than 10 years'],
          'default_values' => ['None'],
          'required' => false,
          'values' => ['None'] # The default value
        ))
      end
    end

    context 'with invalid saved value' do
      before do
        background_field.update_values(user, ['0'], validate: false)
      end

      describe "invalid field's value" do
        subject(:json_field) do
          json['fields'].find {|f| f['name'] == 'background' }
        end

        it "is field's default values" do
          expect(json_field['values']).to eq background_field.default_values
        end
      end
    end
  end

  describe 'PATCH update' do
    subject(:response) { patch :update, params: }

    context 'with text field' do
      let!(:field) { create(:custom_text_field) }

      context 'with valid string' do
        let(:params) { {user_id: user.id, fields: [{id: field.id, values: ['text']}]} }

        it { is_expected.to have_http_status :ok }

        it 'has correct location header' do
          expect(response.headers['Location']).to eq user_profile_url(user)
        end

        it 'creates custom field value' do
          expect { response }.to change(CustomFieldValue, :count).from(0).to(1)

          CustomFieldValue.first.tap do |value|
            expect(value.values).to eq ['text']
            expect(value.context).to eq user
            expect(value.custom_field_id).to eq field.id
          end
        end
      end

      shared_examples_for 'a blank value' do |values|
        let(:params) do
          {
            user_id: user.id,
            fields: [{id: field.id, values:}],
          }
        end

        it { is_expected.to have_http_status :ok }

        it 'has correct location header' do
          expect(response.headers['Location']).to eq user_profile_url(user)
        end

        it 'does not create a custom field value' do
          expect { response }.not_to change(CustomFieldValue, :count).from(0)
        end

        context 'with existing value' do
          before { field.update_values(user, ['text']) }

          it 'destroys existing custom field value' do
            expect { response }.to change(CustomFieldValue, :count).from(1).to(0)
          end
        end

        context 'when required' do
          let(:field) { create(:custom_text_field, required: true) }

          it { is_expected.to have_http_status :ok }

          it 'does not create a custom field value' do
            expect { response }.not_to change(CustomFieldValue, :count).from(0)
          end
        end

        context 'when required and previously set' do
          let(:field) { create(:custom_text_field, required: true) }

          before { field.update_values(user, ['text']) }

          it { is_expected.to have_http_status :unprocessable_entity }

          it 'responds with error JSON' do
            expect(json['errors']).to include 'fn' => ['required']
          end

          it 'does not create a custom field value' do
            expect { response }.not_to change(CustomFieldValue, :count).from(1)
          end
        end
      end

      context 'with empty string' do
        it_behaves_like 'a blank value', ['']
      end

      context 'with empty array' do
        it_behaves_like 'a blank value', []
      end
    end

    context 'with select field' do
      let!(:field) do
        create(:custom_select_field, values: %w[0 1 2], default_values: %w[0])
      end

      context 'with invalid value' do
        let(:params) do
          {
            user_id: user.id,
            fields: [{id: field.id, values: ['fff']}],
          }
        end

        it { is_expected.to have_http_status :unprocessable_entity }

        it 'responds with error JSON' do
          expect(json['errors']).to include 'fn' => ['values not allowed']
        end
      end

      context 'with valid value' do
        let(:params) do
          {
            user_id: user.id,
            fields: [{id: field.id, values: ['1']}],
          }
        end

        it { is_expected.to have_http_status :ok }

        it 'has correct location header' do
          expect(response.headers['Location']).to eq user_profile_url(user)
        end

        it 'includes saved value' do
          expect(json['fields'].first['values']).to eq ['1']
        end

        it 'creates custom field value' do
          expect { response }.to change(CustomFieldValue, :count).from(0).to(1)

          CustomFieldValue.first.tap do |value|
            expect(value.values).to eq ['1']
            expect(value.context).to eq user
            expect(value.custom_field_id).to eq field.id
          end
        end
      end

      context 'with default value set' do
        let(:params) do
          {
            user_id: user.id,
            fields: [{
              id: field.id,
              values: field.default_values,
            }],
          }
        end

        it { is_expected.to have_http_status :ok }

        it 'has correct location header' do
          expect(response.headers['Location']).to eq user_profile_url(user)
        end

        it 'does not create a custom field value' do
          expect { response }.not_to change(CustomFieldValue, :count).from(0)
        end

        context 'with existing value' do
          before { field.update_values(user, ['1']) }

          it 'destroys existing custom field value' do
            expect { response }.to change(CustomFieldValue, :count).from(1).to(0)
          end
        end

        context 'when required' do
          let(:field) do
            create(:custom_select_field,
              values: %w[0 1 2],
              default_values: %w[0],
              required: true)
          end

          it { is_expected.to have_http_status :ok }

          it 'has correct location header' do
            expect(response.headers['Location']).to eq user_profile_url(user)
          end

          it 'does not create a custom field value' do
            expect { response }.not_to change(CustomFieldValue, :count).from(0)
          end
        end

        context 'when required and previously set' do
          let(:field) do
            create(:custom_select_field,
              values: %w[0 1 2],
              default_values: %w[0],
              required: true)
          end

          before { field.update_values(user, ['1']) }

          it { is_expected.to have_http_status :unprocessable_entity }

          it 'responds with error JSON' do
            expect(json['errors']).to include 'fn' => ['required']
          end

          it 'does not create a custom field value' do
            expect { response }.not_to change(CustomFieldValue, :count).from(1)
          end
        end
      end

      describe 'event notify' do
        before { user }

        let(:params) do
          {
            user_id: user.id,
            fields: [{id: field.id, values: ['1']}],
          }
        end

        it 'publishes an event' do
          expect(Msgr).to receive(:publish) do |payload, opts|
            expect(opts).to eq to: 'xikolo.account.profile.update'
            expect(payload).to eq ProfileDecorator.new([field], user).as_event
          end

          response
        end
      end
    end

    context 'with custom validator' do
      before do
        cls = Class.new(Xikolo::Validators::Base) do
          def validate(_field, _user, values, action)
            return unless action == :save
            return unless values.size > 1 || values.first !~ /^[abc]+$/

            errors << 'INVALID'
          end
        end

        stub_const 'CustomValidator', cls
      end

      let!(:record) do
        create(:custom_text_field,
          title: 'With Custom Validator',
          validator: 'CustomValidator')
      end

      context 'with invalid value' do
        let(:params) do
          {
            user_id: user.id,
            fields: [{id: record.id, values: ['fff']}],
          }
        end

        it { is_expected.to have_http_status :unprocessable_entity }

        it 'responds with error JSON' do
          expect(json['errors']).to include 'fn' => ['INVALID']
        end
      end

      context 'with valid value' do
        let(:params) do
          {
            user_id: user.id,
            fields: [{id: record.id, values: ['aabc']}],
          }
        end

        it { is_expected.to have_http_status :ok }

        it 'saves value in database' do
          expect { response }.to change {
            CustomFieldValue.where(context: user, custom_field: record).size
          }.from(0).to(1)
        end

        it 'includes valid field value' do
          expect(json['fields'].first['values']).to eq ['aabc']
        end
      end
    end

    context 'profile completion' do
      let(:user) { create(:user, completed_profile: false) }

      let!(:field1) do
        create(:custom_text_field, name: 'fn1', required: true)
      end

      let!(:field2) do
        create(:custom_text_field, name: 'fn2', required: true)
      end

      before do
        create(:custom_text_field, name: 'fn3', required: false)

        # Ensure user has no features
        expect(user.features.count).to be_zero
      end

      context 'with required fields filled' do
        let(:params) do
          {
            user_id: user.id,
            fields: [
              {id: field1.id, values: ['text']},
              {id: field2.id, values: ['text']},
            ],
          }
        end

        it 'adds the account.profile.mandatory_completed feature' do
          expect { response }.to change {
            user.features.reload.map(&:name)
          }.from([]).to(['account.profile.mandatory_completed'])
        end
      end

      context 'with already completed profile' do
        let(:params) do
          {
            user_id: user.id,
            fields: [
              {id: field1.id, values: ['new']},
              {id: field2.id, values: ['text']},
            ],
          }
        end

        before do
          field1.update_values(user, ['text'])
          field2.update_values(user, ['text'])
          user.update_profile_completion!

          expect(user).to have_feature 'account.profile.mandatory_completed'
        end

        it { is_expected.to have_http_status :ok }

        it 'responds with update profile values' do
          expect(json).to include 'fields' => [
            a_hash_including(
              'id' => field1.id,
              'values' => ['new']
            ),
            a_hash_including(
              'id' => field2.id,
              'values' => ['text']
            ),
          ]
        end
      end
    end
  end
end

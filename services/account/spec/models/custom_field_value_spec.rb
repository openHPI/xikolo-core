# frozen_string_literal: true

require 'spec_helper'

describe CustomFieldValue, type: :model do
  subject { value }

  let(:attrs) { {} }
  let(:value) { create(:'account_service/custom_field_value', attrs) }

  describe '#values' do
    subject(:values) { value.values }

    it { is_expected.to be_an Array }

    context 'for a select field' do
      let(:attrs) { {custom_field: create(:'account_service/custom_select_field'), values: ['A']} }

      context 'when allowed values were changed after the record was created' do
        before do
          value
          value.custom_field.update(values: %w[new1 new2], default_values: %w[new1])
        end

        it 'returns the new defaults' do
          expect(values).to eq ['new1']
        end
      end
    end
  end

  describe '#histograms' do
    let(:users) { create_list(:'account_service/user', 10) }

    let!(:select_fields) do
      [
        create(:'account_service/custom_select_field',
          name: :it,
          title: 'Background in IT',
          values: ['None', 'Up to 1 year', 'Up to 5 years', 'Up to 10 years', 'More than 10 years'],
          default_values: []),
        create(:'account_service/custom_select_field',
          name: :tech,
          title: 'Foreground in Tech',
          values: ['None', 'Up to 1 year', 'Up to 5 years', 'Up to 10 years', 'More than 10 years'],
          default_values: []),
      ]
    end
    let!(:text_field) do
      create(:'account_service/custom_text_field',
        name: :affiliation,
        title: 'Affiliation')
    end
    let!(:multi_select_field) do
      create(:'account_service/custom_multi_select_field',
        name: :interests,
        title: 'Interests',
        values: ['Cooking', 'Baking', 'Sports', 'Running around'])
    end

    before do
      select_fields[0].update_values(users[1], ['Up to 1 year'])
      select_fields[0].update_values(users[3], ['Up to 1 year'])
      select_fields[0].update_values(users[4], ['Up to 1 year'])
      select_fields[0].update_values(users[2], ['Up to 5 years'])
      select_fields[0].update_values(users[9], ['None'])

      select_fields[1].update_values(users[2], ['Up to 1 year'])
      select_fields[1].update_values(users[8], ['Up to 1 year'])

      text_field.update_values(users[2], ['Company1'])
      text_field.update_values(users[5], ['Company1'])
      text_field.update_values(users[3], [''])
      text_field.update_values(users[7], ['Company2'])

      multi_select_field.update_values(users[3], %w[Cooking Baking])
    end

    # Histograms are too large for text and multi-select fields
    it 'aggregates values for select fields only' do
      expect(described_class.histograms).to eq(
        select_fields[0] => {'None' => 1, 'Up to 1 year' => 3, 'Up to 5 years' => 1},
        select_fields[1] => {'Up to 1 year' => 2}
      )
    end

    it 'can be limited to a custom set of fields' do
      expect(described_class.histograms(select_fields[0])).to eq(
        select_fields[0] => {'None' => 1, 'Up to 1 year' => 3, 'Up to 5 years' => 1}
      )
    end

    it 'does not count default values' do
      select_fields.each {|f| f.update(default_values: ['None']) }

      expect(described_class.histograms).to eq(
        select_fields[0] => {'Up to 1 year' => 3, 'Up to 5 years' => 1},
        select_fields[1] => {'Up to 1 year' => 2}
      )
    end

    it 'can be restricted to users of a certain group' do
      group = create(:'account_service/group')

      group.members << users[1..3]
      group.members << users[5..7]
      group.members << users[9..9]

      expect(described_class.for_members_of(group).histograms).to eq(
        select_fields[0] => {'None' => 1, 'Up to 1 year' => 2, 'Up to 5 years' => 1},
        select_fields[1] => {'Up to 1 year' => 1}
      )
    end
  end
end

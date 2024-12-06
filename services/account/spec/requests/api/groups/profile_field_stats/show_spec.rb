# frozen_string_literal: true

require 'spec_helper'

describe 'Group Profile Field Stats', type: :request do
  subject(:resource) { base.rel(:profile_field_stats).get(id: field_name).value! }

  let(:api) { Restify.new(:test).get.value! }
  let(:base) { api.rel(:group).get(id: group).value! }
  let(:field_name) { 'background' }

  let(:group) { create(:group) }
  let(:users) { create_list(:user, 10) }

  let!(:field) do
    create(:custom_select_field,
      name: :background,
      title: 'Background in IT',
      values: ['None', 'Up to 1 year', 'Up to 5 years',
               'Up to 10 years', 'More than 10 years'],
      default_values: ['None'])
  end

  before do
    group.members << users[1..3]
    group.members << users[5..7]
    group.members << users[9..9]

    field.update_values(users[1], ['Up to 1 year'])
    field.update_values(users[2], ['Up to 5 years'])
    field.update_values(users[3], ['Up to 1 year'])
    field.update_values(users[4], ['Up to 1 year'])
    field.update_values(users[9], ['None'])
  end

  it 'responds with 200 Ok' do
    expect(resource).to respond_with :ok
  end

  it 'includes field information and a histogram' do
    expect(resource).to eq(
      'id' => field.id,
      'name' => 'background',
      'type' => 'CustomSelectField',
      'title' => {'en' => 'Background in IT'},
      'required' => false,
      'default_values' => ['None'],
      'available_values' => ['None', 'Up to 1 year', 'Up to 5 years',
                             'Up to 10 years', 'More than 10 years'],
      'aggregation' => {
        'Up to 1 year' => 2,
        'Up to 5 years' => 1,
      }
    )
  end

  context 'for a field without any submissions' do
    let(:field_name) { 'occupation' }
    let!(:empty_field) do
      create(:custom_select_field,
        name: :occupation,
        title: 'Occupation',
        values: ['None', 'Busy Ness'],
        default_values: ['None'])
    end

    it 'includes field information and an empty histogram' do
      expect(resource).to eq(
        'id' => empty_field.id,
        'name' => 'occupation',
        'type' => 'CustomSelectField',
        'title' => {'en' => 'Occupation'},
        'required' => false,
        'default_values' => ['None'],
        'available_values' => ['None', 'Busy Ness'],
        'aggregation' => {}
      )
    end
  end
end

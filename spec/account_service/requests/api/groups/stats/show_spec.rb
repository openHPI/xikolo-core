# frozen_string_literal: true

require 'spec_helper'

describe 'Group Stats', type: :request do
  subject(:resource) { base.rel(:stats).get(params).value! }

  let(:api) { restify_with_headers(account_service_url).get.value! }
  let(:base) { api.rel(:group).get({id: group}).value! }
  let(:params) { {} }

  let(:group) { create(:'account_service/group') }
  let(:users) { create_list(:'account_service/user', 10) }

  let!(:fields) do
    [
      create(:'account_service/custom_select_field',
        name: :background,
        title: 'Background in IT',
        values: ['None', 'Up to 1 year', 'Up to 5 years',
                 'Up to 10 years', 'More than 10 years'],
        default_values: ['None']),
      create(:'account_service/custom_text_field',
        name: :affiliation,
        title: 'Affiliation'),
    ]
  end

  before do
    group.members << users[1..3]
    group.members << users[5..7]
    group.members << users[9..9]

    # Two users with different time but same date
    users[1].update! born_at: ((7.years + 1.day).ago.beginning_of_day + 14.hours + 45.minutes).utc
    users[2].update! born_at: ((7.years + 1.day).ago.beginning_of_day + 17.hours + 45.minutes).utc

    # A few with different dates
    users[6].update! born_at: (52.years + 1.day).ago.utc
    users[7].update! born_at: (44.years + 1.day).ago.utc

    # Two affiliated users
    users[1].update! affiliated: true
    users[2].update! affiliated: true

    fields[0].update_values(users[1], ['Up to 1 year'])
    fields[0].update_values(users[2], ['Up to 5 years'])
    fields[0].update_values(users[3], ['Up to 1 year'])
    fields[0].update_values(users[9], ['None'])

    fields[0].update_values(users[4], ['Up to 1 year'])

    fields[1].update_values(users[2], ['Company1'])
    fields[1].update_values(users[3], [''])
    fields[1].update_values(users[5], ['Company1'])
    fields[1].update_values(users[7], ['Company2'])
  end

  it 'responds with 200 Ok' do
    expect(resource).to respond_with :ok
  end

  describe '#keys' do
    subject { super().keys }

    it { is_expected.to match %w[members] }
  end

  describe '[members]' do
    subject { super()['members'] }

    it { is_expected.to eq 7 }

    context 'on magic groups' do
      let(:base) { api.rel(:group).get({id: 'all'}).value! }

      it { is_expected.to eq 10 }
    end
  end

  context 'with ?embed=profile' do
    let(:params) { {embed: 'profile'} }

    describe '[profile]' do
      subject(:profile) { resource['profile'].as_json }

      it 'includes profile field information and histograms' do
        expect(profile).to contain_exactly({
          'id' => fields[0].id,
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
          },
        })
      end
    end
  end

  context 'with ?embed=user' do
    let(:params) { {embed: 'user'} }

    describe '[user]' do
      subject { super()['user'].as_json }

      let(:user) do
        {'age' => {
          '7' => 2,
          '44' => 1,
          '52' => 1,
        }}
      end

      it { is_expected.to match user }
    end
  end

  context 'with ?embed=affiliated' do
    let(:params) { {embed: 'affiliated'} }

    describe '[affiliated]' do
      subject { super()['affiliated_members'].as_json }

      let(:affiliated_members) { 2 }

      it { is_expected.to match affiliated_members }
    end
  end
end

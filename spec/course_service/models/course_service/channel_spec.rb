# frozen_string_literal: true

require 'spec_helper'

describe CourseService::Channel, type: :model do
  subject { channel }

  let(:attributes) { {} }
  let(:channel) { create(:'course_service/channel', attributes) }
  let(:uuid) { SecureRandom.uuid }

  it { is_expected.not_to accept_values_for(:code, '') }
  it { is_expected.to accept_values_for(:code, 'company1', 'thoughtleaders') }

  it { is_expected.to accept_values_for(:logo_id, '', uuid) }

  it { is_expected.to accept_values_for(:description, 'Some description', 'another description!', '') }

  it { is_expected.to accept_values_for(:title_translations, {'de' => 'Channel DE', 'en' => 'Channel EN'}) }
  it { is_expected.not_to accept_values_for(:title_translations, {'de' => 'Channel DE', 'en' => ''}) }
  it { is_expected.not_to accept_values_for(:title_translations, {'de' => '', 'en' => 'Channel EN'}) }
  it { is_expected.not_to accept_values_for(:title_translations, {'fr' => 'Channel FR', 'en' => 'Channel EN'}) }

  it 'allows assigning multiple courses to a channel' do
    course1 = create(:'course_service/course', channels: [channel])
    course2 = create(:'course_service/course', channels: [channel])

    expect(channel.courses).to contain_exactly(course1, course2)
  end

  it { is_expected.to accept_values_for(:highlight, true, false) }

  it { is_expected.to accept_values_for(:affiliated, true, false) }

  it { is_expected.not_to accept_values_for(:position, 'hello', 'world', 1.2) }
  it { is_expected.to accept_values_for(:position, 0, 1, 2, nil) }

  describe '#by_identifier' do
    let!(:code_channel) { create(:'course_service/channel', code: 'abc') }
    let!(:uuid_channel) { create(:'course_service/channel', id: '1b8a0864-7e37-4454-8fd4-065dadd6de62') }
    let!(:java_channel) { create(:'course_service/channel', code: 'javaeinstieg2015') }

    # The ID is the UUID from `javaeinstieg2015` which is a valid base62 encoded UUID.
    let!(:javu_channel) { create(:'course_service/channel', id: '00000000-2fa0-4226-87da-3909a7886973') }

    before do
      # Some noise records to ensure they are not included.
      create(:'course_service/channel', id: '91f09c1f-c512-4998-92b6-95066dba6bd1')
    end

    it 'matches channel code' do
      expect(CourseService::Channel.by_identifier('abc')).to eq [code_channel]
    end

    it 'matches channel CourseService::UUID' do
      expect(CourseService::Channel.by_identifier('1b8a0864-7e37-4454-8fd4-065dadd6de62')).to eq [uuid_channel]
    end

    it 'matches channel code and short CourseService::UUID' do
      expect(CourseService::Channel.by_identifier('javaeinstieg2015')).to contain_exactly(java_channel, javu_channel)
    end
  end
end

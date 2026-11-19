# frozen_string_literal: true

require 'spec_helper'

describe CourseService::CourseDecorator do
  let(:decorator) { described_class.new(course) }
  let(:course) { create(:'course_service/course', **attrs) }
  let(:attrs) { {} }

  before do
    create(:'course_service/cluster', id: 'category')
    create(:'course_service/cluster', id: 'zzz')
  end

  context '(version 1)' do
    subject(:json) { decorator.as_json(api_version: 1).stringify_keys }

    before do
      stub_request(:get, %r{\Ahttp://richtext.xikolo.tld/rich_texts/[-0-9a-f]+\z})
        .and_return(Stub.json({markup: 'Empty'}))
    end

    it 'exports default fields' do
      expect(json.keys).to match_array %w[
        id
        course_code
        course_format
        context_id
        special_groups
        title
        url
        abstract
        description
        start_date
        display_start_date
        end_date
        enrollment_delta
        alternative_teacher_text
        teacher_ids
        external_course_url
        forum_is_locked
        public
        lang
        welcome_mail
        invite_only
        classifiers
        channels
        middle_of_course
        middle_of_course_is_auto
        on_demand
        pinboard_enabled
        records_released
        roa_threshold_percentage
        cop_threshold_percentage
        roa_enabled
        cop_enabled
        video_course_codes
        learning_goals
        created_at
        updated_at
        enable_video_download
        students_group_url
        teacher_text
        published
        placement
      ]
    end

    describe '#classifiers' do
      # Ensure we pass a non-ordered set of classifiers
      # that are returned ordered
      let(:attrs) do
        {
          classifiers: {
            zzz: %w[z a],
            category: %w[pro-track databases],
          },
        }
      end

      it 'includes ordered set of classifiers' do
        expect(json['classifiers']).to eq \
          'category' => %w[databases pro-track],
          'zzz' => %w[a z]
      end
    end

    describe '#students_group_url' do
      subject { json['students_group_url'] }

      it { is_expected.to eq "http://localhost:3000/account_service/groups/course.#{course.course_code}.students" }
    end

    context 'with custom course middle' do
      subject { json['middle_of_course_is_auto'] }

      let(:course) { create(:'course_service/course', :with_custom_middle_date) }

      it { is_expected.to be false }
    end

    context 'auto flag for course middle' do
      subject { json['middle_of_course_is_auto'] }

      let(:course) { create(:'course_service/course') }

      it { is_expected.to be true }
    end

    context 'with channel' do
      let(:channel_code) { 'mychannel' }
      let(:channel) { create(:'course_service/channel', code: channel_code, title_translations: {'de' => 'Disney Channel', 'en' => 'Disney Channel'}) }
      let(:course) { create(:'course_service/course', channels: [channel]) }

      it 'includes channel attributes' do
        expect(json['channels'].first['code']).to eq channel_code
        expect(json['channels'].first.dig('title_translations', 'en')).to eq 'Disney Channel'
      end
    end
  end
end

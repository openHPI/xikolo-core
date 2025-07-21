# frozen_string_literal: true

require 'spec_helper'

describe CourseDecorator do
  let(:decorator) { described_class.new(course) }
  let(:course) { create(:course, **attrs) }
  let(:attrs) { {} }

  before do
    create(:cluster, id: 'category')
    create(:cluster, id: 'zzz')

    Stub.service(
      :account,
      group_url: '/groups/{id}'
    )
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
        status
        alternative_teacher_text
        teacher_ids
        external_course_url
        forum_is_locked
        public
        hidden
        show_on_list
        lang
        welcome_mail
        auto_archive
        show_syllabus
        invite_only
        classifiers
        channel_id
        channel_name
        channel_code
        middle_of_course
        middle_of_course_is_auto
        on_demand
        pinboard_enabled
        proctored
        records_released
        roa_threshold_percentage
        cop_threshold_percentage
        roa_enabled
        cop_enabled
        video_course_codes
        rating_stars
        rating_votes
        learning_goals
        target_groups
        created_at
        updated_at
        stage_visual_url
        stage_statement
        show_on_stage
        enable_video_download
        policy_url
        students_group_url
        prerequisite_status_url
        achievements_url
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

      it { is_expected.to eq "http://account.xikolo.tld/groups/course.#{course.course_code}.students" }
    end

    context 'with custom course middle' do
      subject { json['middle_of_course_is_auto'] }

      let(:course) { create(:course, :with_custom_middle_date) }

      it { is_expected.to be false }
    end

    context 'auto flag for course middle' do
      subject { json['middle_of_course_is_auto'] }

      let(:course) { create(:course) }

      it { is_expected.to be true }
    end

    context 'with channel' do
      let(:channel_code) { 'mychannel' }
      let(:channel) { create(:channel, code: channel_code, name: 'Disney Channel') }
      let(:course) { create(:course, channel:) }

      it 'includes channel attributes' do
        expect(json['channel_code']).to eq channel_code
        expect(json['channel_name']).to eq 'Disney Channel'
      end
    end
  end

  describe '(version 2)' do
    subject(:json) { decorator.as_json(api_version: 2).stringify_keys }

    let(:course) do
      Course.where(id: super().id).from('embed_courses AS courses').take!
    end

    it 'exports default fields' do
      expect(json.keys).to match_array %w[
        id
        course_code
        title
        abstract
        learning_goals
        target_groups
        teachers
        language
        channel_code
        classifiers
        state
        hidden
        invite_only
        proctored
        start_date
        end_date
        roa_threshold_percentage
        cop_threshold_percentage
        roa_enabled
        cop_enabled
        accessible
        on_demand
        show_on_list
        enrollments_url
        created_at
        updated_at
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
  end
end

# frozen_string_literal: true

require 'spec_helper'

RSpec.describe VisitCreateJob, type: :job do
  subject(:perform_job) { described_class.perform_now(payload) }

  let!(:user)   { create(:'account_service/user') }
  let!(:course) { create(:course) }

  let(:score_attributes) do
    attributes_for(
      :gamification_score,
      :visit_create,
      course_id: course.id,
      user_id: user.id
    )
  end

  let(:payload) do
    {
      id: score_attributes[:data][:visit_id],
      user_id: user.id,
      course_id: score_attributes[:course_id],
      item_id: score_attributes[:data][:item_id],
      section_id: score_attributes[:data][:section_id],
      created_at: DateTime.iso8601('2015-01-20T04:05:06+07:00'),
    }
  end

  before do
    Stub.request(
      :course, :get, '/items',
      query: {section_id: score_attributes[:data][:section_id]}
    ).to_return Stub.json([])
  end

  # ------------------------------------------------------------
  # Unattended section
  # ------------------------------------------------------------

  context 'for unattended section' do
    it 'creates a new score' do
      expect { perform_job }
        .to change(Gamification::Score, :count)
        .from(0).to(1)
    end

    context 'with correctly created score' do
      before { perform_job }

      it 'has correct points' do
        expect(Gamification::Score.first.points).to eq 0
      end

      it 'has correct rule' do
        expect(Gamification::Score.first.rule).to eq 'visited_item'
      end
    end

    context 'with existing score' do
      before do
        create(
          :gamification_score,
          :visit_create,
          course: course,
          user: user,
          data: score_attributes[:data]
        )
      end

      it 'does not create a new score' do
        expect { perform_job }
          .not_to change(Gamification::Score, :count)
      end
    end
  end

  # ------------------------------------------------------------
  # Attended section
  # ------------------------------------------------------------

  context 'for attended section' do
    let!(:score_1) do
      create(:gamification_score, :take_selftest, course:, user:, data: score_attributes[:data])
    end

    before do
      create(:gamification_score, :take_exam, course:, user:, data: score_attributes[:data])

      Stub.request(
        :course, :get, '/items',
        query: {section_id: score_1.data[:section_id]}
      ).to_return Stub.json([
        {id: score_1.data[:item_id], content_type: 'Video::Video'},
      ])

      Stub.request(
        :course, :get, '/sections',
        query: {course_id: score_1.course_id}
      ).to_return Stub.json([
        {id: score_1.data[:section_id]},
      ])
    end

    it 'creates two new scores' do
      expect { perform_job }
        .to change(Gamification::Score, :count)
        .from(2).to(4)
    end

    context 'with correctly created score' do
      before { perform_job }

      it 'has correct points' do
        expect(Gamification::Score.pluck(:points))
          .to contain_exactly(0, 0, 0, 0)
      end

      it 'has correct rules' do
        expect(Gamification::Score.pluck(:rule))
          .to match_array(%w[take_selftest take_exam visited_item attended_section])
      end
    end

    context 'with existing attended_section score' do
      before do
        create(
          :gamification_score,
          :attended_section,
          course: course,
          user: user,
          data: {section_id: score_attributes[:data][:section_id]}
        )
      end

      it 'only creates one new score' do
        expect { perform_job }
          .to change(Gamification::Score, :count)
          .by(1)
      end
    end
  end

  # ------------------------------------------------------------
  # Continuous attendance
  # ------------------------------------------------------------

  context 'for continuous attendance' do
    let(:previous_section_id) { '00000004-3300-4444-9999-000000000001' }
    let(:section_id)          { '00000004-3300-4444-9999-000000000002' }
    let(:item_id)             { '00000003-3300-4444-9999-000000000002' }

    let(:score_attributes) do
      attributes_for(
        :gamification_score,
        :visit_create,
        course_id: course.id,
        user_id: user.id,
        data: {
          visit_id: '00000002-3300-4444-9999-000000000002',
          item_id: item_id,
          section_id: section_id,
        }
      )
    end

    before do
      create(:gamification_score, :attended_section, course:, user:,
        data: {section_id: previous_section_id})

      create(:gamification_score, :take_selftest, course:, user:,
        data: {
          result_id: '00000002-3300-4444-9999-000000000002',
          item_id: item_id,
          section_id: section_id,
        })

      create(:gamification_score, :take_exam, course:, user:, data: score_attributes[:data])

      Stub.request(
        :course, :get, '/items',
        query: {section_id: section_id}
      ).to_return Stub.json([
        {id: item_id, content_type: 'Video::Video'},
      ])

      Stub.request(
        :course, :get, '/sections',
        query: {course_id: course.id}
      ).to_return Stub.json([
        {id: previous_section_id},
        {id: section_id},
      ])
    end

    it 'creates three new scores' do
      expect { perform_job }
        .to change(Gamification::Score, :count)
        .from(3).to(6)
    end

    context 'with existing continuous attendance score' do
      before do
        create(:gamification_score, :continuous_attendance, course:, user:)
      end

      it 'still creates three new scores' do
        expect { perform_job }
          .to change(Gamification::Score, :count)
          .from(4).to(7)
      end
    end

    context 'with existing continuous attendance for section' do
      before do
        create(:gamification_score, :continuous_attendance, course:, user:,
          data: {section_id: section_id})
      end

      it 'only creates two new scores' do
        expect { perform_job }
          .to change(Gamification::Score, :count)
          .by(2)
      end
    end

    context 'with unknown section_id' do
      before do
        Stub.request(
          :course, :get, '/sections',
          query: {course_id: course.id}
        ).to_return Stub.json([
          {id: previous_section_id},
        ])
      end

      it 'does not raise error' do
        expect { perform_job }.not_to raise_error
      end
    end
  end
end

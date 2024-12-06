# frozen_string_literal: true

require 'spec_helper'

describe 'xikolo.course.result.create' do
  subject(:new_result) do
    publish.call
    Msgr::TestPool.run count: 1
  end

  let!(:user) { create(:user) }
  let!(:course) { create(:course) }
  let(:score_attributes) { attributes_for(:gamification_score, :take_exam, course_id: course.id, user_id: user.id) }
  let(:points) { 1 }
  let(:max_points) { 10 }
  let(:deadline) { DateTime.iso8601('2015-01-26T04:05:06+07:00') }
  let(:payload) do
    {
      id: score_attributes[:data][:result_id],
      user_id: user.id,
      course_id: score_attributes[:course_id],
      item_id: score_attributes[:data][:item_id],
      section_id: score_attributes[:data][:section_id],
      exercise_type:,
      submission_deadline: deadline,
      created_at: DateTime.iso8601('2015-01-20T04:05:06+07:00'),
      points:,
      max_points:,
    }
  end
  let(:publish) { -> { Msgr.publish payload, to: 'xikolo.course.result.create' } }

  before do
    # The order of setting the config and then starting Msgr is important as the
    # routes are registered only when the service is available.
    Xikolo.config.gamification = {'enabled' => true}
    Msgr.client.start
    Stub.service(:course, build(:'course:root'))
  end

  context 'for early submission' do
    let(:exercise_type) { 'main' }

    it 'creates a new score' do
      expect { new_result }.to change(Gamification::Score, :count).from(0).to(1)
    end

    context 'with correctly created score' do
      before { new_result }

      it 'the score has correct points' do
        expect(Gamification::Score.first.points).to eq 0
      end

      it 'the score has correct rule' do
        expect(Gamification::Score.first.rule).to eq 'take_exam'
      end
    end

    context 'with existing score' do
      before { create(:gamification_score, :take_exam, user:, course:, data: score_attributes[:data]) }

      it 'does not create a new score' do
        expect { new_result }.not_to change(Gamification::Score, :count)
      end
    end

    context 'without a submission deadline' do
      let(:deadline) { nil }

      it 'does not create a new score' do
        expect { new_result }.not_to change(Gamification::Score, :count)
      end
    end

    context 'for attended section' do
      let!(:score_1) do
        create(:gamification_score, :visit_create, user:, course:,
          data: score_attributes[:data])
      end

      before do
        create(:gamification_score, :take_selftest, user:, course:, data: score_attributes[:data])

        Stub.request(
          :course, :get, '/items',
          query: {section_id: score_1.data[:section_id]}
        ).to_return Stub.json([
          {
            id: score_1.data[:item_id],
            content_type: 'video',
          },
        ])
        Stub.request(
          :course, :get, '/sections',
          query: {course_id: score_1.course_id}
        ).to_return Stub.json([
          {
            id: score_1.data[:section_id],
          },
        ])
      end

      it 'creates two new scores' do
        expect { new_result }.to change(Gamification::Score, :count).from(2).to(4)
      end

      context 'with correctly created score' do
        before { new_result }

        it 'the scores have correct points' do
          expect(Gamification::Score.pluck(:points)).to contain_exactly(0, 0, 0, 0)
        end

        it 'the scores have correct rules' do
          expect(Gamification::Score.pluck(:rule)).to match_array(%w[visited_item take_selftest take_exam attended_section])
        end
      end

      context 'with existing score' do
        before { create(:gamification_score, :attended_section, user:, course:, data: {section_id: score_attributes[:data][:section_id]}) }

        it 'creates only one new score (no attended_section score)' do
          expect { new_result }.to change(Gamification::Score, :count).by(1)
        end
      end
    end
  end

  context 'for taking a selftest' do
    let(:exercise_type) { 'selftest' }
    let(:score_attributes) { attributes_for(:gamification_score, :take_selftest, course_id: course.id, user_id: user.id) }

    it 'creates a new score' do
      expect { new_result }.to change(Gamification::Score, :count).from(0).to(1)
    end

    context 'with correctly created score' do
      before { new_result }

      it 'the score has correct points' do
        expect(Gamification::Score.first.points).to eq 0
      end

      it 'the score has correct rule' do
        expect(Gamification::Score.first.rule).to eq 'take_selftest'
      end
    end

    context 'with existing score' do
      before { create(:gamification_score, :take_selftest, course:, user:, data: score_attributes[:data]) }

      it 'does not create a new score' do
        expect { new_result }.not_to change(Gamification::Score, :count)
      end
    end

    context 'with full points' do
      let(:score_attributes) do
        attributes_for(:gamification_score, :selftest_master, course_id: course.id, user_id: user.id)
      end
      let(:points) { 10 }

      it 'creates two new scores' do
        expect { new_result }.to change(Gamification::Score, :count).from(0).to(2)
      end

      context 'with correctly created score' do
        before { new_result }

        it 'the scores have correct points' do
          expect(Gamification::Score.pluck(:points)).to contain_exactly(0, 2)
        end

        it 'the scores have correct rules' do
          expect(Gamification::Score.pluck(:rule)).to match_array(%w[take_selftest selftest_master])
        end
      end

      context 'with existing score' do
        before do
          create(:gamification_score, :take_selftest, course:, user:, data: score_attributes[:data])
          create(:gamification_score, :selftest_master, course:, user:, data: score_attributes[:data])
        end

        it 'does not create a new score' do
          expect { new_result }.not_to change(Gamification::Score, :count)
        end
      end
    end

    context 'for attended section' do
      let!(:score_1) { create(:gamification_score, :visit_create, course:, user:, data: score_attributes[:data]) }

      before do
        # Second score
        create(:gamification_score, :take_exam, course:, user:, data: score_1.data)

        Stub.request(
          :course, :get, '/items',
          query: {section_id: score_1.data[:section_id]}
        ).to_return Stub.json([
          {
            id: score_1.data[:item_id],
            content_type: 'video',
          },
        ])
        Stub.request(
          :course, :get, '/sections',
          query: {course_id: score_1.course_id}
        ).to_return Stub.json([
          {
            id: score_1.data[:section_id],
          },
        ])
      end

      it 'creates two new scores' do
        expect { new_result }.to change(Gamification::Score, :count).from(2).to(4)
      end

      context 'with correctly created score' do
        before { new_result }

        it 'the scores have correct points' do
          expect(Gamification::Score.pluck(:points)).to contain_exactly(0, 0, 0, 0)
        end

        it 'the scores have correct rules' do
          expect(Gamification::Score.pluck(:rule)).to match_array(%w[visited_item take_exam take_selftest attended_section])
        end
      end

      context 'with existing score' do
        before { create(:gamification_score, :attended_section, course:, user:, data: {section_id: score_attributes[:data][:section_id]}) }

        it 'creates only one new score (no attended_section score)' do
          expect { new_result }.to change(Gamification::Score, :count).by(1)
        end
      end
    end
  end

  context 'with wrong exercise type' do
    let(:exercise_type) { 'bonus' }

    before { expect(Gamification::Score.count).to eq 0 }

    it 'does not create a new score' do
      expect { new_result }.not_to change(Gamification::Score, :count)
    end
  end

  context 'for continuous attendance' do
    let(:score_attributes) do
      attributes_for(:gamification_score, :take_selftest, course_id: course.id, user_id: user.id,
        data: {
          result_id: '00000002-3300-4444-9999-000000000002',
          item_id:,
          section_id:,
        })
    end
    let(:previous_section_id) { '00000004-3300-4444-9999-000000000001' }
    let(:section_id) { '00000004-3300-4444-9999-000000000002' }
    let(:item_id) { '00000003-3300-4444-9999-000000000002' }
    let(:exercise_type) { 'selftest' }

    before do
      create(:gamification_score, :attended_section, course:, user:,
        data: {section_id: previous_section_id})

      create(:gamification_score, :visit_create, course:, user:,
        data: {
          visit_id: '00000002-3300-4444-9999-000000000002',
          item_id:,
          section_id:,
        })

      # Score sub 2
      create(:gamification_score, :take_exam, course:, user:,
        data: {
          result_id: '00000002-3300-4444-9999-000000000002',
          item_id:,
          section_id:,
        })

      Stub.request(
        :course, :get, '/items',
        query: {section_id:}
      ).to_return Stub.json([
        {id: item_id, content_type: 'video'},
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
      expect { new_result }.to change(Gamification::Score, :count).from(3).to(6)
    end

    context 'with correctly created score' do
      before { new_result }

      it 'the scores have correct points' do
        # TODO: this is a dirty fix, the whole test seems to be flawed to me.
        # Maybe it would be sufficient to at least rename the context
        expect(Gamification::Score.pluck(:points)).to contain_exactly(0, 0, 0, 0, 0, 0)
      end

      it 'the scores have correct rules' do
        expect(Gamification::Score.pluck(:rule)).to match_array(
          %w[
            attended_section visited_item take_exam
            take_selftest attended_section continuous_attendance
          ]
        )
      end
    end

    context 'with existing score' do
      before { create(:gamification_score, :continuous_attendance, course:, user:, data: {section_id: score_attributes[:data][:section_id]}) }

      it 'only creates two new scores (no continuous attendance)' do
        expect { new_result }.to change(Gamification::Score, :count).by(2)
      end
    end

    context 'with existing continuous attendance' do
      # Existing score
      before { create(:gamification_score, :continuous_attendance, course:, user:) }

      it 'creates three new scores' do
        expect { new_result }.to change(Gamification::Score, :count).from(4).to(7)
      end

      context 'with correctly created score' do
        before { new_result }

        it 'the scores have correct points' do
          expect(Gamification::Score.pluck(:points)).to contain_exactly(0, 0, 0, 0, 10, 10, 0)
        end

        it 'the scores have correct rules' do
          expect(Gamification::Score.pluck(:rule)).to match_array(
            %w[
              continuous_attendance attended_section
              visited_item take_exam
              take_selftest attended_section
              continuous_attendance
            ]
          )
        end
      end
    end
  end
end

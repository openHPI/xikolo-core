# frozen_string_literal: true

require 'spec_helper'

describe 'xikolo.course.visit.create' do
  subject(:new_visit) do
    publish.call
    Msgr::TestPool.run count: 1
  end

  let!(:user) { create(:user) }
  let!(:course) { create(:course) }
  let(:score_attributes) { attributes_for(:gamification_score, :visit_create, course_id: course.id, user_id: user.id) }
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
  let(:publish) { -> { Msgr.publish payload, to: 'xikolo.course.visit.create' } }

  before do
    # The order of setting the config and then starting Msgr is important as the
    # routes are registered only when the service is available.
    Xikolo.config.gamification = {'enabled' => true}
    Msgr.client.start
    Stub.request(
      :course, :get, '/items',
      query: {section_id: score_attributes[:data][:section_id]}
    ).to_return Stub.json([])
  end

  context 'for unattended section' do
    it 'creates a new score' do
      expect { new_visit }.to change(Gamification::Score, :count).from(0).to(1)
    end

    context 'with correctly created score' do
      before { new_visit }

      it 'the score has correct points' do
        expect(Gamification::Score.first.points).to eq 0
      end

      it 'the score has correct rule' do
        expect(Gamification::Score.first.rule).to eq 'visited_item'
      end
    end

    context 'with existing score' do
      before { create(:gamification_score, :visit_create, course:, user:, data: score_attributes[:data]) }

      it 'does not create a new score' do
        expect { new_visit }.not_to change(Gamification::Score, :count)
      end
    end
  end

  context 'for attended section' do
    let!(:score_1) { create(:gamification_score, :take_selftest, course:, user:, data: score_attributes[:data]) }

    before do
      # Second score
      create(:gamification_score, :take_exam, course:, user:, data: score_attributes[:data])

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
        query: {course_id: score_1[:course_id]}
      ).to_return Stub.json([
        {
          id: score_1.data[:section_id],
        },
      ])
    end

    it 'creates two new scores' do
      expect { new_visit }.to change(Gamification::Score, :count).from(2).to(4)
    end

    context 'with correctly created score' do
      before { new_visit }

      it 'the scores have correct points' do
        expect(Gamification::Score.pluck(:points)).to contain_exactly(0, 0, 0, 0)
      end

      it 'the scores have correct rules' do
        expect(Gamification::Score.pluck(:rule)).to match_array(%w[take_selftest take_exam visited_item attended_section])
      end
    end

    context 'with existing score' do
      before { create(:gamification_score, :attended_section, course:, user:, data: {section_id: score_attributes[:data][:section_id]}) }

      it 'only creates one new score (no attended section)' do
        expect { new_visit }.to change(Gamification::Score, :count).by(1)
      end
    end
  end

  context 'for continuous attendance' do
    let(:score_attributes) do
      attributes_for(:gamification_score, :visit_create, course_id: course.id,
        data: {
          visit_id: '00000002-3300-4444-9999-000000000002',
          item_id:,
          section_id:,
        })
    end
    let(:previous_section_id) { '00000004-3300-4444-9999-000000000001' }
    let(:section_id) { '00000004-3300-4444-9999-000000000002' }
    let(:item_id) { '00000003-3300-4444-9999-000000000002' }

    let(:stubs) do
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

    before do
      create(:gamification_score, :attended_section, course:, user:,
        data: {section_id: previous_section_id})

      create(:gamification_score, :take_selftest, course:, user:,
        data: {
          result_id: '00000002-3300-4444-9999-000000000002',
          item_id:,
          section_id:,
        })

      # Second score sub 2
      create(:gamification_score, :take_exam, course:, user:, data: score_attributes[:data])
      # Stub items and sections
      stubs
    end

    it 'creates three new scores' do
      expect { new_visit }.to change(Gamification::Score, :count).from(3).to(6)
    end

    context 'with correctly created score' do
      before { new_visit }

      it 'the scores have correct points' do
        # TODO: this is a dirty fix, the whole test seems to be flawed to me.
        # Maybe it would be sufficient to at least rename the context
        expect(Gamification::Score.pluck(:points)).to contain_exactly(0, 0, 0, 0, 0, 0)
      end

      it 'the scores have correct rules' do
        expect(Gamification::Score.pluck(:rule)).to match_array(
          %w[
            attended_section take_selftest take_exam
            visited_item attended_section continuous_attendance
          ]
        )
      end
    end

    context 'with existing score' do
      before { create(:gamification_score, :continuous_attendance, course:, user:, data: {section_id:}) }

      it 'only creates two new scores (no continuous attendance)' do
        expect { new_visit }.to change(Gamification::Score, :count).by(2)
      end
    end

    context 'with existing continuous attendance' do
      # Existing score
      before { create(:gamification_score, :continuous_attendance, course:, user:) }

      it 'creates three new scores' do
        expect { new_visit }.to change(Gamification::Score, :count).from(4).to(7)
      end

      context 'with correctly created score' do
        before { new_visit }

        it 'the scores have correct points' do
          expect(Gamification::Score.pluck(:points)).to contain_exactly(0, 0, 0, 0, 10, 10, 0)
        end

        it 'the scores have correct rules' do
          expect(Gamification::Score.pluck(:rule)).to match_array(
            %w[
              continuous_attendance attended_section
              take_selftest take_exam
              visited_item attended_section
              continuous_attendance
            ]
          )
        end
      end
    end

    context 'with unknown section_id (like alternative child section)' do
      let(:stubs) do
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
        ])
      end

      it 'does not fail' do
        expect { new_visit }.not_to raise_error
      end

      it 'handles alternative sections correctly' do
        skip 'TODO XI-3433'
      end
    end
  end
end

# frozen_string_literal: true

require 'spec_helper'

describe Gamification::Score, type: :model do
  subject { score }

  let(:score) { build(:gamification_score) }

  it { is_expected.not_to accept_values_for :rule, '' }

  describe '.total' do
    subject(:total) { described_class.total }

    it 'returns zero' do
      expect(total).to eq 0
    end

    context 'with scores for different users' do
      let(:user) { create(:user) }

      before do
        create_list(:gamification_score, 2, user:, points: 3)
        create_list(:gamification_score, 3, points: 5)
      end

      it 'can be used to sum up scores for a specific user' do
        expect(user.gamification_scores.total).to eq 6
      end
    end
  end

  describe 'creation' do
    let(:user) { create(:user) }

    context 'scores for posts in the pinboard' do
      it 'creates a Communicator badge' do
        create_list(:gamification_score, 2, :question_create, user:)

        expect { create(:gamification_score, :comment_create, user:) }
          .to change(Gamification::Badge, :count).from(0).to(1)

        expect(Gamification::Badge.first).to have_attributes(
          name: 'communicator',
          level: 0
        )
      end

      it 'creates only one badge' do
        expect { create_list(:gamification_score, 5, :question_create, user:) }
          .to change(Gamification::Badge, :count).from(0).to(1)
      end

      it 'creates a badge for each level given enough scores' do
        create_list(:gamification_score, 13, :question_create, user:) # rubocop:disable FactoryBot/ExcessiveCreateList

        expect(Gamification::Badge.pluck(:level)).to contain_exactly(0, 1, 2)
      end
    end

    context 'scores for accepted pinboard answers' do
      it 'creates a Knowledgeable badge' do
        create_list(:gamification_score, 2, :accepted_answer, user:)

        expect { create(:gamification_score, :accepted_answer, user:) }
          .to change(Gamification::Badge, :count).from(0).to(1)

        expect(Gamification::Badge.first).to have_attributes(
          name: 'knowledgeable',
          level: 0
        )
      end
    end

    context 'scores for selftest mastery' do
      let(:course) { create(:course) }

      it 'creates a Selftest Master badge for the correct course' do
        create_list(:gamification_score, 19, :selftest_master, user:, course:) # rubocop:disable FactoryBot/ExcessiveCreateList

        expect { create(:gamification_score, :selftest_master, user:, course:) }
          .to change(Gamification::Badge, :count).from(0).to(1)

        expect(Gamification::Badge.first).to have_attributes(
          name: 'selftest_master',
          level: 2,
          course:
        )
      end

      context 'for several courses' do
        let(:courses) { create_list(:course, 3) }

        before do
          courses.each do |course|
            create_list(:gamification_score, 20, :selftest_master, course:, user:) # rubocop:disable FactoryBot/ExcessiveCreateList
          end
        end

        it 'creates a Selftest Master badge in each course' do
          expect(Gamification::Badge.pluck(:course_id)).to match_array(courses.map(&:id))
        end
      end
    end
  end
end

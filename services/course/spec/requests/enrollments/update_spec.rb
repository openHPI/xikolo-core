# frozen_string_literal: true

require 'spec_helper'

describe 'Enrollment: Update', type: :request do
  let(:api) { Restify.new(:test).get.value! }

  let(:user_id) { generate(:user_id) }

  def patch(data)
    api.rel(:enrollment).patch(data, params: {id: enrollment.id}).value!
  end

  context 'updating proctored' do
    let(:enrollment) { create(:enrollment, user_id:, proctored:) }

    context 'without paid proctored' do
      let(:proctored) { false }

      it 'changes the value' do
        expect { patch(proctored: true) }.to change { enrollment.reload.proctored }.from(false).to(true)
      end

      it 'does not change without the value' do
        expect { patch({}) }.not_to change { enrollment.reload.proctored }.from(false)
      end
    end

    context 'with paid proctored' do
      let(:proctored) { true }

      it 'does not change the value on nil' do
        expect { patch(proctored: nil) }.not_to change { enrollment.reload.proctored }.from(true)
      end

      it 'does not change without the value' do
        expect { patch({}) }.not_to change { enrollment.reload.proctored }.from(true)
      end
    end
  end

  context 'updating completed' do
    let(:enrollment) do
      create(:enrollment,
        user_id:,
        completed:,
        course:)
    end
    let(:completed) { nil }
    let(:course) { create(:course) }
    let(:fetch_learning_evaluation) do
      Enrollment.with_learning_evaluation(Enrollment.all).find(enrollment.id)
    end

    context 'with auto-state true' do
      let(:course) { create(:course, records_released: true) }
      let(:section) { create(:section, course:) }
      let(:item) { create(:item, section:, exercise_type: 'main', content_type: 'quiz', max_dpoints: 50) }

      before do
        create(:result, item:, user_id:, dpoints: 49)

        e = fetch_learning_evaluation
        e.completed = nil
        expect(e.completed?).to be true
      end

      context 'with previously nil' do
        let(:completed) { nil }

        it 'assign nil should stay to auto-mode' do
          expect { patch completed: nil }.not_to \
            change { enrollment.reload.completed }.from(nil)
        end

        it 'assign true should stay to auto-mode' do
          expect { patch completed: true }.not_to \
            change { enrollment.reload.completed }.from(nil)
        end

        it 'assign false should change it to false' do
          expect { patch completed: false }.to \
            change { enrollment.reload.completed }.from(nil).to(false)
        end
      end

      context 'with previously true forced' do
        let(:completed) { true }

        it 'assign nil should switch to auto-mode' do
          expect { patch completed: nil }.to \
            change { enrollment.reload.completed }.from(true).to(nil)
        end

        it 'assign true should return to auto-mode' do
          expect { patch completed: true }.to \
            change { enrollment.reload.completed }.from(true).to(nil)
        end

        it 'assign false should change it to false' do
          expect { patch completed: false }.to \
            change { enrollment.reload.completed }.from(true).to(false)
        end
      end

      context 'with previously false forced' do
        let(:completed) { false }

        it 'assign nil should switch to auto-mode' do
          expect { patch completed: nil }.to \
            change { enrollment.reload.completed }.from(false).to(nil)
        end

        it 'assign true should return to auto-mode' do
          expect { patch completed: true }.to \
            change { enrollment.reload.completed }.from(false).to(nil)
        end

        it 'assign false should not change it' do
          expect { patch completed: false }.not_to \
            change { enrollment.reload.completed }.from(false)
        end
      end
    end

    context 'with auto-state false' do
      before do
        e = fetch_learning_evaluation
        e.completed = nil
        expect(e.completed?).to be false
      end

      context 'with previously nil' do
        let(:completed) { nil }

        it 'assign nil should stay to auto-mode' do
          expect { patch completed: nil }.not_to \
            change { enrollment.reload.completed }.from(nil)
        end

        it 'assign true should change it to true' do
          expect { patch completed: true }.to \
            change { enrollment.reload.completed }.from(nil).to(true)
        end

        it 'assign false should stay to auto-mode' do
          expect { patch completed: false }.not_to \
            change { enrollment.reload.completed }.from(nil)
        end
      end

      context 'with previously true forced' do
        let(:completed) { true }

        it 'assign nil should switch to auto-mode' do
          expect { patch completed: nil }.to \
            change { enrollment.reload.completed }.from(true).to(nil)
        end

        it 'assign true should not change it' do
          expect { patch completed: true }.not_to \
            change { enrollment.reload.completed }.from(true)
        end

        it 'assign false should return to auto-mode' do
          expect { patch completed: false }.to \
            change { enrollment.reload.completed }.from(true).to(nil)
        end
      end

      context 'with previously false forced' do
        let(:completed) { false }

        it 'assign nil should switch to auto-mode' do
          expect { patch completed: nil }.to \
            change { enrollment.reload.completed }.from(false).to(nil)
        end

        it 'assign true should change it to true' do
          expect { patch completed: true }.to \
            change { enrollment.reload.completed }.from(false).to(true)
        end

        it 'assign false should return to auto-mode' do
          expect { patch completed: false }.to \
            change { enrollment.reload.completed }.from(false).to(nil)
        end
      end
    end
  end

  context 'with forced_submission_date' do
    let!(:now) { DateTime.now.midnight }
    let(:enrollment) { create(:enrollment, user_id:, forced_submission_date: nil) }

    it 'cannot be set by UPDATE' do
      expect do
        patch forced_submission_date: now
      end.not_to change {
        enrollment.reload.forced_submission_date
      }.from nil
    end
  end
end

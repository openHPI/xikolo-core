# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TimeeffortService::Item, type: :model do
  subject { item }

  let(:time_effort) { 20 }
  let(:calculated_time_effort) { 30 }
  let(:item) do
    create(:'timeeffort_service/item',
      time_effort:, calculated_time_effort:)
  end

  it { is_expected.to accept_values_for(:content_type, 'video', 'rich_text', 'quiz') }
  it { is_expected.to accept_values_for(:content_type, 'lti_exercise') }
  it { is_expected.to accept_values_for(:time_effort, 10) }
  it { is_expected.not_to accept_values_for(:time_effort, 10.5, -12) }
  it { is_expected.to accept_values_for(:calculated_time_effort, 10) }
  it { is_expected.not_to accept_values_for(:calculated_time_effort, 10.5, -12) }

  describe '#set_calculated_time_effort' do
    subject(:set_effort) { item.set_calculated_time_effort(new_time_effort) }

    context 'w/o time effort overwritten' do
      context 'w/ new calculated_time_effort' do
        let(:new_time_effort) { 40 }

        it 'updates the calculated time effort' do
          expect { set_effort }.to change { item.reload.calculated_time_effort }
            .from(calculated_time_effort)
            .to(new_time_effort)
        end

        it 'updates the time effort' do
          expect { set_effort }.to change { item.reload.time_effort }.from(time_effort).to(new_time_effort)
        end

        it 'returns successful operation' do
          expect(set_effort.success?).to be true
        end
      end

      context 'w/o new calculated_time_effort' do
        let(:new_time_effort) { calculated_time_effort }

        it 'does not update the item' do
          expect { set_effort }.not_to change { item.reload.updated_at }
        end

        it 'returns not successful operation' do
          expect(set_effort.success?).to be false
        end
      end
    end

    context 'w/ time effort overwritten' do
      let(:item) do
        create(:'timeeffort_service/item', :time_effort_overwritten,
          time_effort:, calculated_time_effort:)
      end
      let(:new_time_effort) { 40 }

      it 'updates the calculated time effort' do
        expect { set_effort }.to change { item.reload.calculated_time_effort }
          .from(calculated_time_effort)
          .to(new_time_effort)
      end

      it 'does not update the time effort' do
        expect { set_effort }.not_to change { item.reload.time_effort }
      end

      it 'returns not successful operation' do
        expect(set_effort.success?).to be true
      end
    end
  end

  describe '#overwrite_time_effort' do
    subject(:overwrite_effort) { item.overwrite_time_effort(new_time_effort) }

    let(:old_time_effort) { 22 }
    let(:new_time_effort) { 55 }
    let(:item) { create(:'timeeffort_service/item', time_effort: old_time_effort) }

    it 'sets the new time effort' do
      expect { overwrite_effort }.to change { item.reload.time_effort }.from(old_time_effort).to(new_time_effort)
    end

    it 'marks the time effort as overwritten' do
      expect { overwrite_effort }.to change { item.reload.time_effort_overwritten }.from(false).to(true)
    end
  end

  describe '#clear_overwritten_time_effort' do
    subject(:clear_effort) { item.clear_overwritten_time_effort }

    let(:old_time_effort) { 22 }
    let(:calculated_time_effort) { 55 }

    let(:item) do
      create(:'timeeffort_service/item', :time_effort_overwritten,
        time_effort: old_time_effort, calculated_time_effort:)
    end

    it 'sets the calculated value as time effort' do
      expect { clear_effort }.to change { item.reload.time_effort }.from(old_time_effort).to(calculated_time_effort)
    end

    it 'marks the time effort as not overwritten' do
      expect { clear_effort }.to change { item.reload.time_effort_overwritten }.from(true).to(false)
    end
  end

  describe '#processor' do
    subject(:processor) { item.processor }

    let(:item) { create(:'timeeffort_service/item', content_type:) }

    context 'rich_text item' do
      let(:content_type) { 'rich_text' }

      it 'returns a RichTextProcessor' do
        expect(processor).to be_a TimeeffortService::Processors::RichTextProcessor
      end
    end

    context 'video item' do
      let(:content_type) { 'video' }

      it 'returns a VideoProcessor' do
        expect(processor).to be_a TimeeffortService::Processors::VideoProcessor
      end
    end

    context 'quiz item' do
      let(:content_type) { 'quiz' }

      it 'returns a QuizProcessor' do
        expect(processor).to be_a TimeeffortService::Processors::QuizProcessor
      end
    end
  end
end

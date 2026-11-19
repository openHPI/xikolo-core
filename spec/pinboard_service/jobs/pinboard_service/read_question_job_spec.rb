# frozen_string_literal: true

require 'spec_helper'

describe PinboardService::ReadQuestionJob, type: :job do
  subject(:perform_job) { described_class.new.perform(user_id, question_id, timestamp) }

  let(:question_id) { '0c4963fd-c17e-41ad-ad6b-71df292e6de0' }
  let(:user_id)     { 'd0160b58-5a11-4e1f-b8e3-35467daf6daa' }
  let(:timestamp)   { Time.zone.now }

  before do
    create(:'pinboard_service/question', id: question_id)
  end

  describe '#perform' do
    context 'first time' do
      it 'creates a new Watch' do
        expect { perform_job }
          .to change(PinboardService::Watch, :count)
          .from(0).to(1)
      end
    end

    context 'second time' do
      let!(:watch) do
        create(
          :'pinboard_service/watch',
          user_id: user_id,
          question_id: question_id,
          updated_at: 1.year.ago
        )
      end

      it 'updates Watch' do
        expect { perform_job }
          .to change { watch.reload.updated_at }
      end

      context 'given someone else is watching' do
        let!(:other_watch) do
          create(
            :'pinboard_service/watch',
            question_id: question_id,
            updated_at: 1.year.ago
          )
        end

        it 'does not update Watch of someone else' do
          expect { perform_job }
            .not_to change { other_watch.reload.updated_at }
        end
      end
    end
  end
end

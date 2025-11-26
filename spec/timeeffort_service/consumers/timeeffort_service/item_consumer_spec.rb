# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TimeeffortService::ItemConsumer, type: :consumer do
  subject(:item_event) do
    publish.call
    Msgr::TestPool.run count: 1
  end

  before do
    # The order of setting the config and then starting Msgr is important as the
    # routes are registered only when the service is available.
    Xikolo.config.timeeffort = {'enabled' => true}
    Msgr.client.start
  end

  let(:course_item_id) { SecureRandom.uuid }
  let(:content_id) { SecureRandom.uuid }
  let(:section_id) { '00000002-3300-4444-9999-000000000001' }
  let(:course_id) { SecureRandom.uuid }

  let(:payload) do
    {
      id: course_item_id,
      content_id:,
      content_type: 'video',
      section_id:,
      course_id:,
    }
  end
  let(:publish) { -> { Msgr.publish(payload, to: msgr_route) } }

  describe '#create_or_update' do
    let(:msgr_route) { 'xikolo.course.item.create' }
    let(:time_effort_job) { instance_double(TimeeffortService::TimeEffortJob) }

    before do
      Stub.service(:course, build(:'course:root'))
    end

    context 'w/ course item existing' do
      let!(:course_item_stub) do
        Stub.request(:course, :get, "/items/#{course_item_id}")
          .to_return Stub.json({
            id: course_item_id,
            section_id: payload[:section_id],
          })
      end

      context 'w/o existing item' do
        it 'creates a new Item' do
          expect { item_event }.to change(TimeeffortService::Item, :count).from(0).to(1)
        end

        it 'sets the section_id correctly' do
          item_event
          expect(TimeeffortService::Item.last.section_id).to eq payload[:section_id]
        end

        it 'requests the current item' do
          item_event
          expect(course_item_stub).to have_been_requested
        end

        it 'creates a new TimeEffortJob' do
          expect { item_event }.to change(TimeeffortService::TimeEffortJob, :count).from(0).to(1)
        end

        it 'schedules a new TimeEffortJob' do
          expect(TimeeffortService::TimeEffortJob).to receive(:create!).once.and_return time_effort_job
          expect(time_effort_job).to receive(:schedule).once
          item_event
        end

        context 'w/o default time effort provided' do
          it 'does not set the time effort' do
            item_event
            expect(TimeeffortService::Item.last.time_effort).to be_nil
          end

          it 'does not mark time effort as overwritten' do
            item_event
            expect(TimeeffortService::Item.last.time_effort_overwritten).to be false
          end
        end

        context 'w/ default time effort provided' do
          let(:payload) { super().merge(time_effort: 40) }

          it 'sets the time effort correctly' do
            item_event
            expect(TimeeffortService::Item.last.time_effort).to eq payload[:time_effort]
          end

          it 'does mark time effort as overwritten' do
            item_event
            expect(TimeeffortService::Item.last.time_effort_overwritten).to be true
          end
        end
      end

      context 'w/ existing item' do
        let(:item_params) do
          {
            id: payload[:id],
            content_id:,
            content_type: 'video',
            section_id:,
            course_id:,
          }
        end
        let!(:item) { create(:'timeeffort_service/item', item_params) }

        it 'does not create a new Item' do
          expect { item_event }.not_to change(TimeeffortService::Item, :count)
        end

        it 'creates a TimeEffortJob for the item and schedules a new job' do
          expect(TimeeffortService::TimeEffortJob).to receive(:create!).once
            .with(item_id: item.id)
            .and_return(time_effort_job)
          expect(time_effort_job).to receive(:schedule).once
          item_event
        end

        it 'requests the current item' do
          item_event
          expect(course_item_stub).to have_been_requested
        end

        context 'w/ new section_id' do
          let(:new_section_id) { '00000002-3300-4444-9999-000000000002' }
          let(:payload) { super().merge(section_id: new_section_id) }

          it 'updates the section id accordingly' do
            expect { item_event }.to change { TimeeffortService::Item.last.section_id }
              .from(section_id)
              .to(new_section_id)
          end
        end
      end

      context 'w/o automatic calculation supported for content type' do
        let(:payload) { super().merge(content_type: 'lti_exercise') }

        it 'creates a new Item' do
          expect { item_event }.to change(TimeeffortService::Item, :count).from(0).to(1)
        end

        it 'does not create a new TimeEffortJob' do
          expect { item_event }.not_to change(TimeeffortService::TimeEffortJob, :count)
        end
      end
    end

    context 'w/o course item existing (anymore)' do
      before do
        Stub.request(:course, :get, "/items/#{course_item_id}")
          .to_return Stub.response(status: 404)
      end

      it 'does not raise an error' do
        expect { item_event }.not_to raise_error
      end

      it 'does not create a new TimeEffortJob' do
        expect { item_event }.not_to change(TimeeffortService::TimeEffortJob, :count)
      end

      it 'destroys the previously created item' do
        item_event
        expect(TimeeffortService::Item.count).to eq 0
      end
    end

    context 'w/ different (unhandled) error' do
      before do
        Stub.request(:course, :get, "/items/#{course_item_id}")
          .to_return Stub.response(status: 400)
      end

      it 'does raise an error' do
        expect { item_event }.to raise_error Restify::ClientError
      end

      it 'does not destroy the previously created item' do
        expect { item_event }.to raise_error Restify::ClientError do
          expect(TimeeffortService::Item.count).to eq 1
        end
      end
    end
  end

  describe '#destroy' do
    let(:msgr_route) { 'xikolo.course.item.destroy' }

    context 'w/ existing item' do
      let!(:item) { create(:'timeeffort_service/item') }
      let(:payload) { {id: item.id} }

      it 'destroys the Item' do
        expect { item_event }.to change(TimeeffortService::Item, :count).from(1).to(0)
      end

      context 'w/ active job' do
        let(:existing_time_effort_job) { create(:'timeeffort_service/time_effort_job', item_id: payload[:id]) }

        before do
          # Ensure the time effort job exists
          existing_time_effort_job
        end

        it 'calls cancel on the existing job' do
          expect(TimeeffortService::TimeEffortJob).to receive(:cancel_active_jobs).with(item.id).once
          item_event
        end
      end
    end

    context 'w/o existing item' do
      let(:payload) { {id: SecureRandom.uuid} }

      it 'does not raise an error' do
        expect { item_event }.not_to raise_error
      end
    end
  end
end

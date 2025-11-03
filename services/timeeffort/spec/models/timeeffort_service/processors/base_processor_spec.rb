# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TimeeffortService::Processors::BaseProcessor, type: :model do
  let(:time_effort) { 10 }
  let(:item) { create(:'timeeffort_service/item', time_effort:) }
  let(:processor) { described_class.new item }

  describe '#initialize' do
    it 'initializes the time effort correctly' do
      expect(processor.time_effort).to be_nil
    end
  end

  describe '#patch_items!' do
    subject(:patch_items) { processor.patch_items! }

    context 'w/ valid time effort' do
      let(:course_item_stub_status) { 200 }

      let!(:course_item_stub) do
        Stub.service(:course, build(:'course:root'))
        Stub.request(
          :course, :patch, "/items/#{item.id}",
          body: hash_including(time_effort: item.time_effort)
        ).to_return Stub.response(status: course_item_stub_status)
      end

      before do
        processor.instance_variable_set(:@time_effort, time_effort)

        allow(TimeeffortService::Item).to receive(:find).with(item.id).and_return(item)
        allow(item).to receive(:set_calculated_time_effort).once
          .with(time_effort)
          .and_return set_calculated_time_effort_operation
      end

      context 'w/ set_calculated_time_effort success' do
        let(:set_calculated_time_effort_operation) { TimeeffortService::Operation.new }

        context 'w/ time effort overwritten' do
          let(:item) { create(:'timeeffort_service/item', :time_effort_overwritten, time_effort:) }

          it 'does not patch the course item' do
            patch_items
            expect(course_item_stub).not_to have_been_requested
          end
        end

        context 'w/o time effort overwritten' do
          it 'patches the course item' do
            patch_items
            expect(course_item_stub).to have_been_requested
          end

          context 'w/ not existing course item' do
            let(:course_item_stub_status) { 404 }

            it 'does not raise an error' do
              expect { patch_items }.not_to raise_error
            end
          end

          context 'w/ other error while patching course item' do
            let(:course_item_stub_status) { 422 }

            it 'raises an error' do
              expect { patch_items }.to raise_error TimeeffortService::Errors::CourseItemUpdateError
            end
          end
        end
      end

      context 'w/o set_calculated_time_effort success' do
        let(:new_time_effort) { time_effort }
        let(:set_calculated_time_effort_operation) { TimeeffortService::Operation.with_errors({'some_field' => 'some_error'}) }

        it 'does not patch the course item' do
          patch_items
          expect(course_item_stub).not_to have_been_requested
        end
      end
    end

    context 'w/o valid time effort' do
      it 'raises an error' do
        expect { patch_items }.to raise_error TimeeffortService::Errors::InvalidTimeEffort
      end
    end
  end
end

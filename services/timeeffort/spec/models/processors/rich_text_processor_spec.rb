# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Processors::RichTextProcessor, type: :model do
  let(:content_type) { 'rich_text' }
  let(:item) { create(:item, content_type:) }
  let(:processor) { described_class.new item }

  describe '#initialize' do
    it 'initializes the video correctly' do
      expect(processor.rich_text).to be_nil
    end
  end

  describe '#load_resources!' do
    subject(:load_resources) { processor.load_resources! }

    let(:rich_text_stub) do
      Stub.request(:course, :get, "/richtexts/#{item.content_id}")
    end

    before do
      Stub.service(:course, build(:'course:root'))
      rich_text_stub
    end

    context 'w/ valid content type' do
      it 'requests the rich_text' do
        load_resources
        expect(rich_text_stub).to have_been_requested
      end
    end

    context 'w/o valid content type' do
      let(:content_type) { 'quiz' }

      it 'raises an error' do
        expect { load_resources }.to raise_error Errors::InvalidItemType
        expect(rich_text_stub).not_to have_been_requested
      end
    end

    context 'w/ error while loading rich_text' do
      let(:rich_text_stub) do
        Stub.request(:course, :get, "/richtexts/#{item.content_id}")
          .to_return Stub.response(status: 404)
      end

      it 'raises an error' do
        expect { load_resources }.to raise_error Errors::LoadResourcesError
        expect(rich_text_stub).to have_been_requested
      end
    end
  end

  describe '#calculate' do
    subject(:calculate_time_effort) { processor.calculate }

    let(:rich_text) { {'text' => 'Sample markup'} }
    let(:time_effort) { 30 }

    context 'w/ rich_text resource' do
      let(:rich_text_handler) { instance_double(ItemTypes::RichText) }

      before do
        processor.instance_variable_set(:@rich_text, rich_text)
      end

      it 'calls the richtext handler and sets the time effort correctly' do
        allow(ItemTypes::RichText).to receive(:new).and_return(rich_text_handler)
        allow(rich_text_handler).to receive(:time_effort).and_return(time_effort)
        calculate_time_effort
        expect(processor.time_effort).to eq time_effort
      end
    end

    context 'w/o rich_text resource' do
      it 'does not set time effort' do
        expect { calculate_time_effort }.not_to change(processor, :time_effort)
      end
    end
  end
end

# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Item::Create do
  subject(:create_item) { described_class.call(item:, content: video, section: section_resource) }

  let(:course) { create(:course) }
  let(:section) { create(:section, course:) }
  let(:section_resource) { build(:'course:section', id: section.id, course_id: course.id) }
  let(:item) { build(:item) }
  # The tags_create_stub is needed for successful item creation and actually
  # loaded in before actions for scenarios requiring it
  let(:tags_create_stub) do
    Stub.request(
      :pinboard, :post, '/implicit_tags',
      body: hash_including(course_id: course['id'])
    ).to_return Stub.response(status: 201)
  end

  before do
    Stub.service(:course, build(:'course:root'))
    Stub.request(:course, :get,
      "/sections/#{section.id}").to_return Stub.json(section_resource)
    Stub.service(:pinboard, build(:'pinboard:root'))
  end

  context 'with a video as the content' do
    let(:video) { create(:video) }

    context 'with valid item and a valid video' do
      before do
        tags_create_stub
      end

      it 'saves the item' do
        expect { create_item }.to change(item, :persisted?).from(false).to(true)
      end

      it 'does not change the video' do
        expect { create_item }.not_to change(video, :reload)
      end

      it "sets the item's content_id and section_id" do
        expect { create_item }.to change(item, :content_id).from(nil).to(video.id).and change(item, :section_id).from(nil).to(section.id)
      end

      it 'creates the pinboard tags' do
        create_item
        expect(tags_create_stub).to have_been_requested
      end
    end

    context 'with an invalid item' do
      before do
        allow(item).to receive(:save!).and_raise(Acfs::InvalidResource)
      end

      it 'handles the error gracefully' do
        expect { create_item }.not_to raise_error
      end

      it "sets the item's content_id and section_id" do
        expect { create_item }.to change(item, :content_id).from(nil).to(video.id).and change(item, :section_id).from(nil).to(section.id)
      end

      it 'does not save the item' do
        expect { create_item }.not_to change(item, :persisted?).from(false)
      end

      it 'destroys the video' do
        expect { create_item }.to change(video, :destroyed?).from(false).to(true)
      end

      it 'does not create the pinboard tags' do
        create_item
        expect(tags_create_stub).not_to have_been_requested
      end
    end

    context 'with an invalid video' do # rubocop:disable RSpec/EmptyExampleGroup
      # This can never happen when having a video as the item's content
      # In ItemsController#create, the Video::Store operation is called before this operation
      # That's why, the video is either successfully persisted
      # Or it's operation returns an error and this operation never gets called
    end
  end
end

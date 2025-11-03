# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Topics: Index', type: :request do
  subject(:resource) { service.rel(:topics).get(params).value! }

  let(:service) { Restify.new(:test).get.value! }

  let(:params) { {} }

  let!(:question1) { create(:'pinboard_service/video_question', :with_commented_answer, tags: [video_item_tag]) }
  let!(:question2) { create(:'pinboard_service/video_question', :with_commented_answer, tags: [video_item_tag]) }
  let(:video_item_tag) { create(:'pinboard_service/video_item_tag') }
  let(:other_item_tag) { create(:'pinboard_service/video_item_tag') }

  before do
    # Question on another item
    create(:'pinboard_service/video_question', :with_commented_answer, tags: [other_item_tag])

    # Question in the global course forum
    create(:'pinboard_service/question', :with_commented_answer)

    # A deleted question
    create(:'pinboard_service/video_question', :with_commented_answer, deleted: true, tags: [video_item_tag])

    # A blocked question
    create(:'pinboard_service/video_question', :with_commented_answer, workflow_state: :blocked, tags: [video_item_tag])
  end

  context 'without filter params' do
    it { is_expected.to respond_with :ok }

    it 'returns no topics (for now)' do
      expect(resource.size).to eq(0)
    end
  end

  context 'filtering by item_id' do
    let(:params) { {item_id: video_item_tag.name} }

    it { is_expected.to respond_with :ok }

    it 'returns only the matching topics' do
      expect(resource.pluck('id')).to contain_exactly(question1.id, question2.id)
    end

    describe '(json)' do
      it {
        expect(resource).to all include(
          'id', 'title', 'abstract', 'tags', 'closed', 'meta', 'created_at'
        )
      }

      it { is_expected.to all have_rel :self }
      it { is_expected.not_to include include 'posts' }
    end

    context 'for an item_id where no matching tag exists' do
      let(:params) { {item_id: SecureRandom.uuid} }

      it { is_expected.to respond_with :ok }
      it { is_expected.to be_empty }
    end
  end

  describe '(pagination)' do
    let(:params) { {item_id: video_item_tag.name, per_page: 1} }

    it 'only shows one item per page, as requested' do
      expect(resource).to have(1).item
    end

    it 'allows navigating to the next page' do
      expect(resource).to have_rel :next
    end

    describe 'the second page' do
      subject(:second_page) { resource.rel(:next).get.value! }

      it 'shows another item' do
        expect(second_page).to have(1).item
      end

      it 'does not have a next page' do
        expect(second_page).not_to have_rel :next
      end
    end
  end
end

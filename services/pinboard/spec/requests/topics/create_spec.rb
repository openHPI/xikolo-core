# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Topics: Create', type: :request do
  subject(:creation) { service.rel(:topics).post(attrs).value! }

  let(:service) { Restify.new(:test).get.value! }

  let(:attrs) do
    {
      title: 'I am happy, because...',
      author_id: generate(:user_id),
      course_id:,
      first_post: {
        text: 'I can create topics, woah',
      },
    }
  end
  let(:course_id) { generate(:course_id) }

  it { is_expected.to respond_with :created }

  it 'creates a new question object' do
    expect { creation }.to change(Question, :count).from(0).to(1)
  end

  it 'stores the text in the question object' do
    creation
    expect(Question.last.text).to eq 'I can create topics, woah'
  end

  context 'with a video_timestamp in the meta hash' do
    let(:attrs) do
      super().merge(
        meta: {
          video_timestamp: 1357,
        }
      )
    end

    describe 'the question' do
      subject(:created_question) { creation; Question.last }

      it 'stores the timestamp in the correct question attribute' do
        expect(created_question.video_timestamp).to eq 1357
      end
    end
  end

  context 'with tags' do
    let(:attrs) do
      super().merge(
        tags: %w[tag1 tag2 tag3]
      )
    end

    it 'creates new explicit tags' do
      expect { creation }.to change(ExplicitTag, :count).from(0).to(3)
    end

    it 'assigns all tags correctly' do
      creation
      question = Question.last
      expect(question.explicit_tags.map(&:name)).to match_array %w[tag1 tag2 tag3]
      expect(question.explicit_tags.map(&:course_id)).to eq Array.new(3, course_id)
    end

    context 'when one of the tags already exists' do
      let!(:existing_tag) { create(:explicit_tag, name: 'tag1', course_id:) }

      it 'does not create a duplicate tag for the already existing one' do
        expect { creation }.to change(ExplicitTag, :count).from(1).to(3)

        # This will trigger ActiveRecord::RecordNotFound in case the existing tag was deleted
        expect { existing_tag.reload }.not_to raise_error
      end

      it 'assigns all tags correctly' do
        creation
        question = Question.last
        expect(question.explicit_tags.map(&:name)).to match_array %w[tag1 tag2 tag3]
        expect(question.explicit_tags.map(&:course_id)).to eq Array.new(3, course_id)
      end
    end
  end

  context 'with an item_id' do
    let(:attrs) { super().merge(item_id:) }
    let(:item_id) { generate(:item_id) }
    let(:section_id) { generate(:section_id) }

    before do
      Stub.service(
        :course,
        item_url: '/items/{id}'
      )
      Stub.request(
        :course, :get, "/items/#{item_id}"
      ).to_return Stub.json({
        section_id:,
      })
    end

    it 'creates two new implicit tag, one each for section and item' do
      expect { creation }.to change(ImplicitTag, :count).from(0).to(2)

      expect(ImplicitTag.all).to contain_exactly(have_attributes(name: item_id, referenced_resource: 'Xikolo::Course::Item'), have_attributes(name: section_id, referenced_resource: 'Xikolo::Course::Section'))
    end

    context 'when the section tag already exists' do
      let!(:existing_tag) { create(:section_tag, name: section_id, course_id:) }

      it 'creates a new implicit tag for the item, and reuses the section tag' do
        expect { creation }.to change(ImplicitTag, :count).from(1).to(2)

        expect(ImplicitTag.all).to contain_exactly(have_attributes(name: item_id, referenced_resource: 'Xikolo::Course::Item'), existing_tag)
      end
    end
  end

  context 'with tags AND an item_id' do
    let(:attrs) do
      super().merge(
        tags: %w[tag1 tag2 tag3],
        item_id:
      )
    end
    let(:item_id) { generate(:item_id) }
    let(:section_id) { generate(:section_id) }

    before do
      Stub.service(
        :course,
        item_url: '/items/{id}'
      )
      Stub.request(
        :course, :get, "/items/#{item_id}"
      ).to_return Stub.json({
        section_id:,
      })
    end

    it 'creates explicit and implicit tags correctly' do
      creation
      question = Question.last

      expect(question.explicit_tags.count).to eq 3
      expect(question.explicit_tags.map(&:name)).to match_array %w[tag1 tag2 tag3]
      expect(question.explicit_tags.map(&:course_id)).to eq Array.new(3, course_id)

      expect(question.implicit_tags.count).to eq 2
      expect(question.implicit_tags).to contain_exactly(have_attributes(name: item_id, referenced_resource: 'Xikolo::Course::Item', course_id:), have_attributes(name: section_id, referenced_resource: 'Xikolo::Course::Section', course_id:))
    end
  end

  context 'with image references' do
    let(:text) { 'upload://b5f99337-224f-40f5-aa82-44ee8b272579/foo.jpg' }
    let(:attrs) { super().merge first_post: {text:} }
    let(:cid) { UUID4(course_id).to_s(format: :base62) }

    it 'stores valid upload and creates a new richtext' do
      stub_request(
        :head,
        'https://s3.xikolo.de/xikolo-uploads/' \
        'uploads/b5f99337-224f-40f5-aa82-44ee8b272579/foo.jpg'
      ).and_return(
        status: 200,
        headers: {
          'X-Amz-Meta-Xikolo-Purpose' => 'pinboard_commentable_text',
          'X-Amz-Meta-Xikolo-State' => 'accepted',
        }
      )
      store_regex = %r{https://s3.xikolo.de/xikolo-pinboard
                       /courses/#{cid}/topics/[0-9a-zA-Z]+/
                       [0-9a-zA-Z]+/foo.jpg}x
      stub_request(:head, store_regex).and_return(status: 404)
      stub_request(:put, store_regex).and_return(status: 200, body: '<xml></xml>')
      expect { creation }.to change(Question, :count).from(0).to(1)
      expect(Question.last.text).to include 's3://xikolo-pinboard'
    end

    it 'rejects invalid upload and does not creates a new page' do
      stub_request(
        :head,
        'https://s3.xikolo.de/xikolo-uploads/' \
        'uploads/b5f99337-224f-40f5-aa82-44ee8b272579/foo.jpg'
      ).and_return(
        status: 200,
        headers: {
          'X-Amz-Meta-Xikolo-Purpose' => 'pinboard_commentable_text',
          'X-Amz-Meta-Xikolo-State' => 'rejected',
        }
      )

      expect { creation }.to raise_error(Restify::ClientError) do |error|
        expect(error.status).to eq :unprocessable_entity
        expect(error.errors).to eq 'text' => ['rtfile_rejected']
      end
    end

    it 'rejects upload on storage errors' do
      stub_request(
        :head,
        'https://s3.xikolo.de/xikolo-uploads/' \
        'uploads/b5f99337-224f-40f5-aa82-44ee8b272579/foo.jpg'
      ).and_return(
        status: 200,
        headers: {
          'X-Amz-Meta-Xikolo-Purpose' => 'pinboard_commentable_text',
          'X-Amz-Meta-Xikolo-State' => 'accepted',
        }
      )
      store_regex = %r{https://s3.xikolo.de/xikolo-pinboard
                       /courses/#{cid}/topics/[0-9a-zA-Z]+/
                       [0-9a-zA-Z]+/foo.jpg}x
      stub_request(:head, store_regex).and_return(status: 404)
      stub_request(:put, store_regex).and_return(status: 503)

      expect { creation }.to raise_error(Restify::ClientError) do |error|
        expect(error.status).to eq :unprocessable_entity
        expect(error.errors).to eq 'text' => ['rtfile_error']
      end
    end
  end
end

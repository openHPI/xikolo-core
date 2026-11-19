# frozen_string_literal: true

require 'spec_helper'

describe 'Items: Update', type: :request do
  let(:api) { restify_with_headers(course_service.root_url).get.value! }
  let(:quiz) { create(:'quiz_service/quiz', question_pool: true, displayed_question_count: 10) }
  let(:item) do
    create(:'course_service/item',
      content_type: 'quiz',
      content_id: quiz.id,
      exercise_type: 'exam',
      published: false)
  end
  let(:original_title) { item.title }

  def patch(data)
    api.rel(:item).patch(data, params: {id: item.id}).value!
  end

  it 'saves an invalid question pool as a draft' do
    expect { patch(title: 'Changed title', published: false) }
      .to change { item.reload.title }.to('Changed title')
  end

  it 'does not publish an invalid question pool' do
    expect { patch(title: 'Changed title', published: true) }
      .to raise_error(Restify::ClientError) do |error|
        expect(error.status).to eq(:unprocessable_content)
      end

    expect(item.reload).to have_attributes(title: original_title, published: false)
  end
end

# frozen_string_literal: true

require 'spec_helper'

describe 'Item: Time Effort', type: :system do
  let(:user_id) { generate(:user_id) }
  let(:features) { {} }
  let(:course) { create(:course, course_code: 'the_course', title: 'Proctored course', proctored: true) }
  let(:course_resource) do
    build(:'course:course', **course_params, id: course.id, course_code: course.course_code, title: course.title,
      proctored: course.proctored)
  end
  let(:course_params) { {} }
  let(:section) { create(:section, course:, title: 'Week 1') }
  let(:section_resource) { build(:'course:section', id: section.id, course_id: course.id, title: section.title) }
  let(:video) { create(:video) }
  let(:item) { build(:'course:item', :video, item_params) }
  let(:item_params) do
    {
      course_id: course.id,
      section_id: section.id,
      content_id: video.id,
      title: 'Awesome video',
      time_effort: 180,
    }
  end

  before do
    stub_user(id: user_id,
      permissions: %w[course.content.access.available],
      features:)

    Stub.request(:account, :get, "/users/#{user_id}")
      .and_return Stub.json({id: user_id})
    Stub.request(:account, :get, "/users/#{user_id}/preferences")
      .and_return Stub.json({properties: {}})

    Stub.request(:course, :get, '/courses/the_course')
      .to_return Stub.json(course_resource)
    Stub.request(
      :course, :get, '/enrollments',
      query: {course_id: course.id, user_id:}
    ).to_return Stub.json([{}])
    Stub.request(
      :course, :get, '/items',
      query: hash_including(section_id: section.id)
    ).to_return Stub.json([item])
    Stub.request(
      :course, :get, "/items/#{item['id']}",
      query: {user_id:}
    ).to_return Stub.json(item)
    Stub.request(:course, :get, "/sections/#{section.id}")
      .to_return Stub.json(section_resource)
    Stub.request(
      :course, :get, '/sections',
      query: {course_id: course.id}
    ).to_return Stub.json([section_resource])
    Stub.request(
      :course, :get, '/next_dates',
      query: hash_including({})
    ).to_return Stub.json([])
    Stub.request(
      :course, :post, "/items/#{item['id']}/users/#{user_id}/visit",
      body: hash_including({})
    ).to_return Stub.response(status: 201)
  end

  context '(video)' do
    before do
      Stub.request(
        :pinboard, :get, '/topics',
        query: {item_id: item['id']}
      ).to_return Stub.json([])
    end

    context 'without time effort being enabled' do
      it 'does not add the time effort information' do
        visit "/courses/the_course/sections/#{section.id}/items/#{item['id']}"

        expect(page.find('li.video > a')['data-tooltip']).not_to include '"item-info":"(Video, \u0026sim;3 minutes)"'
        expect(page).to have_no_content 'Time effort: approx. 3 minutes'
      end
    end

    context 'time effort enabled for all items' do
      let(:features) { super().merge('time_effort' => 'true') }

      it 'adds the time effort information to the item header and tooltip' do
        visit "/courses/the_course/sections/#{section.id}/items/#{item['id']}"

        expect(page).to have_content 'Time effort: approx. 3 minutes'
        expect(page.find('li.video > a')['data-tooltip']).to include '"item-info":"(Video, \u0026sim;3 minutes)"'
      end

      context 'but value set to 0 (i.e., manually hidden)' do
        let(:item_params) do
          {**super(), time_effort: 0}
        end

        it 'does not add the time effort information' do
          visit "/courses/the_course/sections/#{section.id}/items/#{item['id']}"

          expect(page.find('li.video > a')['data-tooltip']).not_to include '"item-info":"(Video, \u0026sim;3 minutes)"'
          expect(page).to have_no_content 'Time effort: approx. 3 minutes'
        end
      end
    end
  end

  context '(quiz)' do
    let(:quiz) { build(:'quiz:quiz', :exam) }
    let(:item) { build(:'course:item', :quiz, :exam, item_params) }
    let(:item_params) do
      {
        **super(),
        content_id: quiz['id'],
        title: 'Awesome exam',
        time_effort: 200,
      }
    end

    before do
      Stub.request(
        :quiz, :get, "/quizzes/#{quiz['id']}",
        query: hash_including({})
      ).to_return Stub.json(quiz)
      Stub.request(
        :quiz, :get, '/questions',
        query: hash_including(quiz_id: quiz['id'])
      ).to_return Stub.json([])
      Stub.request(
        :quiz, :get, '/quiz_submissions',
        query: hash_including(quiz_id: quiz['id'], user_id:)
      ).to_return Stub.json([])
      Stub.request(
        :quiz, :get, '/user_quiz_attempts',
        query: hash_including(quiz_id: quiz['id'], user_id:)
      ).to_return Stub.json({attempts: 0, additional_attempts: 0})
    end

    context 'time effort enabled for all items' do
      let(:features) { super().merge('time_effort' => 'true') }

      it 'adds the time effort information to the item header and tooltip' do
        visit "/courses/the_course/sections/#{section.id}/items/#{item['id']}"

        expect(page).to have_content 'Time effort: approx. 4 minutes'
        expect(page.find('li.quiz > a')['data-tooltip']).to include '"item-info":"(Graded Test, \u0026sim;4 minutes)"'
      end
    end
  end
end

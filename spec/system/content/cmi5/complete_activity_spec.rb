# frozen_string_literal: true

require 'spec_helper'

describe 'Content: Complete a CMI5 activity', type: :system do
  let(:user) { create(:'account_service/user') }
  let(:course) { create(:'course_service/course', :active) }
  let(:section) { create(:'course_service/section', course:) }
  let(:cmi5_item) do
    create(
      :cmi5_item,
      package: Rack::Test::UploadedFile.new(
        Rails.root.join('spec/fixtures/files/cmi5_test_au.zip')
      )
    )
  end
  let!(:item) do
    create(
      :'course_service/item',
      section:,
      content: cmi5_item,
      title: 'CMI5 exercise',
      published: true,
      exercise_type: 'selftest',
      max_dpoints: 100
    )
  end
  let(:passed_statement_id) { SecureRandom.uuid }
  let!(:original_base_url) { Xikolo.base_url }

  before do
    Xikolo.base_url = Capybara.current_session.server.base_url

    Cmi5ItemUnzipJob.perform_now(cmi5_item)

    sign_in(user:)
    enroll_in(course)
  end

  after { Xikolo.base_url = original_base_url }

  it 'launches, initializes, completes, and terminates the activity' do
    visit "/learn/#{course.course_code}/items/#{item.id}"

    within_frame find('iframe[title="Cmi5 content"]') do
      expect(page).to have_css('[data-cmi5-status="initialized"]', text: 'CMI5 activity initialized')

      reporting_response = page.evaluate_async_script(<<~JS)
        const done = arguments[0];
        const passedStatement = statement('passed');
        passedStatement.id = #{passed_statement_id.to_json};
        passedStatement.result = {
          success: true,
        };

        fetch(`${endpoint}/statements`, {
          method: 'POST',
          headers: requestHeaders,
          body: JSON.stringify(passedStatement),
        }).then(successful).then(() => done()).catch((error) => done(error.message));
      JS

      expect(reporting_response).to be_nil

      click_on 'Complete activity'

      expect(page).to have_css('[data-cmi5-status="state-saved"]', text: 'State saved')
      expect(page).to have_css('[data-cmi5-status="completed"]', text: 'CMI5 activity completed')
      expect(page).to have_css('[data-cmi5-status="terminated"]', text: 'CMI5 session terminated')
    end

    expect(CourseService::Result.find(passed_statement_id)).to have_attributes(
      user_id: user.id,
      item_id: item.id,
      dpoints: 100
    )
  end
end

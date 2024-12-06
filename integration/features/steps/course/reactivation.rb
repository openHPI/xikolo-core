# frozen_string_literal: true

module Steps
  module Reactivation
    Given 'the archived course allows reactivation' do
      context.with :archived_course do |course|
        Server[:course].api.rel(:course).patch({on_demand: true}, {id: course['id']}).value!
      end
    end

    Given 'I have a valid voucher for course reactivation' do
      vouchers = Restify.new(
        Addressable::URI.parse(Server[:web].url).join('bridges/shop/vouchers')
      ).post(
        {product: 'course_reactivation', qty: 1, country: 'DE'},
        {},
        headers: {'Authorization' => 'Bearer secret_token'}
      ).value!

      context.assign :voucher, vouchers.first
    end

    When 'I reactivate the course with my voucher' do
      send :'When I enroll in the course'
      send :'When I use the button to reactivate the course'
      send :'When I enter my voucher code'
      send :'When I click on the "Redeem" button'
    end

    Then 'I see a button to reactivate the course' do
      expect(page).to have_content 'Reactivate this course'
    end

    Then 'I do not see a button to reactivate the course' do
      expect(page).not_to have_content 'Reactivate this course'
    end

    When 'I use the button to reactivate the course' do
      click_on 'Reactivate this course'
    end

    Then 'I am informed what reactivation means' do
      expect(page).to have_content <<~TEXT
        Once you redeem the voucher code, you will have 8 weeks to complete the requirements to earn a Record of Achievement.
      TEXT
    end

    When 'I enter my voucher code' do
      context.with :voucher do |voucher|
        fill_in 'Enter your voucher code', with: voucher['id']
      end
    end

    When 'I click on the "Redeem" button' do
      click_on 'Redeem'
    end

    Then 'I see a confirmation of reactivation' do
      expect(page).to have_content 'You have reactivated this course until'
    end

    Then 'I see a toggle to enable reactivation of the course' do
      expect(page).to have_content 'Reactivation'
    end

    Then 'I see a notification for the upcoming course expiration' do
      click_on 'Click to view your upcoming deadlines for this course'
      expect(page).to have_content 'Your course reactivation expires in about 2 months'
    end

    Then 'the quiz deadline is in the future' do
      expect(page).to have_content "Due on #{8.weeks.from_now.strftime('%B %d, %Y')}"
    end
  end
end

Gurke.configure do |c|
  c.include Steps::Reactivation
end

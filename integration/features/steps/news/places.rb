# frozen_string_literal: true

module Steps
  module News
    module Places
      Given 'I am on the news page' do
        visit '/news'
      end

      When 'I am on the news page' do
        send :'Given I am on the news page'
      end

      Given 'I am on the admin announcements list' do
        visit '/admin/announcements'
      end

      When 'I go to the admin announcements list' do
        visit '/'
        click_on 'Administration'
        within '[data-behaviour="menu-dropdown"]' do
          click_on 'Announcements'
        end
      end

      Then 'I should be on the admin announcements list' do
        expect(page).to have_content 'Draft new announcement'
      end
    end
  end
end

Gurke.configure {|c| c.include Steps::News::Places }

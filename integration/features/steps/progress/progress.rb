# frozen_string_literal: true

module Steps
  module Progress
    module Progress
      Then 'the item should be completed' do
        expect(page).to have_content '1 of 1 visited'
      end

      Given 'I count the unvisited items' do
        @counter = page.all('.progress_item:not(.progress_item_visited)').count
      end

      When 'I click on a unvisited item' do
        elem = page.first('.progress_item:not(.progress_item_visited) a')
        elem.click
      end

      Then 'the number of unvisited items is decreased by one' do
        # A step defining @counter needs to be called before
        expect(page).to have_selector('.progress_item:not(.progress_item_visited)', count: @counter - 1)
      end

      Then 'there should be no unpublished item' do
        context.with :items do |items|
          expect(page.html).to include(items.first['title'])
          expect(page.html).to_not include('Unpublished')
          expect(page).to have_selector('.progress_item:not(.progress_item_visited)', count: items.size)
        end
      end
    end
  end
end

Gurke.configure {|c| c.include Steps::Progress::Progress }

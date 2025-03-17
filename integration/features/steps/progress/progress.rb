# frozen_string_literal: true

module Steps
  module Progress
    module Progress
      Then 'the item should be completed' do
        within '.course-progress' do
          expect(find('.course-progress__item', text: 'Completed items')).to have_content('1 of 1')
        end
      end

      Given 'I count the unvisited items' do
        context.with :section do |section|
          click_on section['title']
          @counter = page.all('.section-progress__material-item:not(.section-progress__material-item--completed)').count
        end
      end

      When 'I click on an unvisited item' do
        page.first('a > .section-progress__material-item:not(.section-progress__material-item--completed)').click
      end

      Then 'the number of unvisited items is decreased by one' do
        context.with :section do |section|
          click_on section['title']
          # A step defining @counter needs to be called before
          expect(page).to have_selector(
            '.section-progress__material-item:not(.section-progress__material-item--completed)', count: @counter - 1
          )
        end
      end

      Then 'there should be no unpublished item' do
        context.with :section, :items do |section, items|
          click_on section['title']
          expect(page.html).to include(items.first['title'])
          expect(page.html).to_not include('Unpublished')
          expect(page).to have_selector(
            '.section-progress__material-item:not(.section-progress__material-item--completed)', count: items.size
          )
        end
      end
    end
  end
end

Gurke.configure {|c| c.include Steps::Progress::Progress }

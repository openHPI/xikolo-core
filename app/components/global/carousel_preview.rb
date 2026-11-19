# frozen_string_literal: true

module Global
  class CarouselPreview < ViewComponent::Preview
    # @param item_count number
    def default(item_count: 7)
      render ::Global::Carousel.new(label: 'Teachers') do |carousel|
        item_count.to_i.times do |i|
          carousel.with_item do
            carousel.render ::Course::TeacherCard.new(
              name: "Teacher #{i + 1}",
              description: 'Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod ' \
                           'tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua.',
              picture_url: "https://picsum.photos/seed/teacher#{i}/200"
            )
          end
        end
      end
    end

    # Navigation is hidden when all items fit on one page, and the items grow to fill the row.
    def fits_on_one_page
      default(item_count: 2)
    end

    def single_item
      default(item_count: 1)
    end

    # Fits more items per page; they keep their width when there are few.
    # @param item_count number
    def small(item_count: 7)
      render ::Global::Carousel.new(label: 'Quizzes', size: :sm) do |carousel|
        item_count.to_i.times do |i|
          carousel.with_item do
            carousel.render ::Course::ItemCard.new(
              title: "Week #{i + 1}: How does bias get into AI systems?",
              label: 'Self-test',
              icon: 'learning_material',
              path: '#',
              state: i < 2 ? :completed : :default
            )
          end
        end
      end
    end
  end
end

# frozen_string_literal: true

module Course
  class TeacherCardPreview < ViewComponent::Preview
    LONG_DESCRIPTION = <<~MARKDOWN
      Lorem ipsum dolor sit amet, **consetetur sadipscing elitr**, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua.

      At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet. Lorem ipsum dolor sit amet, consetetur sadipscing elitr.
    MARKDOWN

    # @!group
    def default
      render ::Course::TeacherCard.new(
        name: 'Prof. Dr. Ada Lovelace',
        description: LONG_DESCRIPTION,
        picture_url: 'https://picsum.photos/200'
      )
    end

    def short_description
      render ::Course::TeacherCard.new(
        name: 'Prof. Dr. Ada Lovelace',
        description: 'Lorem ipsum dolor sit amet.',
        picture_url: 'https://picsum.photos/200'
      )
    end

    def without_picture
      render ::Course::TeacherCard.new(
        name: 'Grace Hopper',
        description: LONG_DESCRIPTION
      )
    end
    # @!endgroup
  end
end

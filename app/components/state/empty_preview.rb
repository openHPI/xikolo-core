# frozen_string_literal: true

module State
  class EmptyPreview < ViewComponent::Preview
    # @!group Size variants
    def default_size
      render State::Empty.new('No courses found')
    end

    def small_size
      render State::Empty.new('No courses found', size: :small)
    end

    def compact_size
      render State::Empty.new('No courses found', size: :compact)
    end

    # @!endgroup
    def with_additional_content
      render State::Empty.new('No courses found') do
        'Call to Action'
      end
    end
  end
end

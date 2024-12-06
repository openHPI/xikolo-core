# frozen_string_literal: true

module Global
  class UserAvatar < ApplicationComponent
    def initialize(user_id, size:, type: nil)
      raise ArgumentError.new('Unknown size') unless SIZE_MAPPING.key? size

      @user_id = user_id
      @size = size
      @type = type
    end

    # Mapping of modifier to px
    # When changing these values, please also adapt
    # the respective _profile.scss classes.
    SIZE_MAPPING = {
      tiny: 20,
      small: 30,
      medium: 40,
      large: 60,
      'x-large': 100,
    }.stringify_keys.freeze

    private

    def css_classes
      classes = %w[user-avatar]
      classes << type_class.presence
      classes << size_class.presence
      classes.compact.join(' ')
    end

    def type_class
      # Predefined CSS classes for types: rounded
      @type ? "user-avatar--#{@type}" : ''
    end

    def size_class
      @size ? "user-avatar--#{@size}" : ''
    end

    def user_avatar_path
      avatar_path(@user_id, width: size, height: size)
    end

    def size
      SIZE_MAPPING.fetch(@size)
    end
  end
end

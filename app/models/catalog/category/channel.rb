# frozen_string_literal: true

module Catalog
  module Category
    ##
    # An automatic course category that loads courses in a given channel.
    # All publicly visible courses, regardless of start date and duration,
    # may show up, oldest (by start date) first.
    #
    # A maximum of 4 courses will be loaded.
    #
    class Channel
      ##
      # Get a list of categories, one for each publicly visible channel.
      #
      def self.all_public
        ::Course::Channel.public.ordered.map do |channel|
          new(channel)
        end
      end

      def initialize(channel)
        @channel = channel
      end

      def title
        @channel.name
      end

      def url
        "/channels/#{@channel.code}"
      end

      def courses
        @courses ||= ::Catalog::Course.released
          .for_channel_list(@channel)
          .for_guests
          .order_chronologically
          .take(4)
      end
    end
  end
end

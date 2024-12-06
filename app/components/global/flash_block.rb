# frozen_string_literal: true

module Global
  class FlashBlock < ApplicationComponent
    def initialize(flash)
      @flash = flash
    end

    private

    def messages
      %i[error success notice alert]
        .select {|type| @flash[type] }
        .flat_map do |type|
          @flash[type].uniq.map {|message| {type:, text: message} }
        end
    end

    def layers
      %i[success_layer info_layer error_layer]
        .select {|type| @flash[type] }
        .flat_map do |type|
        @flash[type].map {|message| {type:, text: message} }
      end
    end
  end
end

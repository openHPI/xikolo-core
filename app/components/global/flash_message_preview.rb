# frozen_string_literal: true

module Global
  class FlashMessagePreview < ViewComponent::Preview
    # @!group

    def success
      render Global::FlashMessage.new(:success, 'Success!')
    end

    def error
      render Global::FlashMessage.new(:error, 'Error :(')
    end

    def alert
      render Global::FlashMessage.new(:alert, 'Alert!')
    end

    def notice
      render Global::FlashMessage.new(:notice, 'Notice...')
    end

    def very_long_text
      render Global::FlashMessage.new(:notice,
        'Prow scuttle parrel provost Sail ho shrouds spirits boom mizzenmast yardarm.
        Belay yo-ho-ho keelhaul squiffy black spot yardarm spyglass sheet transom heave to.')
    end

    # @!endgroup
  end
end

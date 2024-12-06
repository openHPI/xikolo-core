# frozen_string_literal: true

module Dashboard
  module Poll
    # @display max_width 400px
    class WidgetPreview < ViewComponent::Preview
      # @param multiple_choice toggle
      def vote(multiple_choice: true)
        poll.allow_multiple_choices = multiple_choice

        render_with_template(
          template: 'dashboard/poll/widget_preview/vote',
          locals: {poll:}
        )
      end

      # @param next_poll toggle
      # @param with_stats toggle
      # @param intermediate_results toggle
      def thanks(next_poll: true, intermediate_results: false, with_stats: false)
        poll.show_intermediate_results = intermediate_results

        render_with_template(
          template: 'dashboard/poll/widget_preview/thanks',
          locals: {
            poll:,
            choices: [poll.options.first.id],
            stats: (with_stats ? many_participants : nil),
            next_poll:,
          }
        )
      end

      private

      def poll
        @poll ||= ::Poll::Poll.new(
          id: SecureRandom.uuid,
          question: 'Where did you hear first about our platform?',
          start_at: 2.weeks.ago,
          end_at: 2.weeks.from_now,
          show_intermediate_results: false,
          options: [
            ::Poll::Option.new(id: SecureRandom.uuid, text: 'Online', position: 1),
            ::Poll::Option.new(id: SecureRandom.uuid, text: 'Offline', position: 2),
          ]
        )
      end

      Stats = Struct.new(:participants, :responses)

      def many_participants
        Stats.new(
          120,
          {
            @poll.options[0] => 45,
            @poll.options[1] => 75,
          }
        )
      end
    end
  end
end

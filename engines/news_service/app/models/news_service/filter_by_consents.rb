# frozen_string_literal: true

module NewsService
class FilterByConsents # rubocop:disable Layout/IndentationWidth
  # `consents` is an array of treatment group identifiers,
  # e.g. ['treatment.abc', 'treatment.def'].
  def initialize(recipient, consents)
    @recipient = recipient
    @consents = consents
  end

  def each(&)
    Enumerator.new do |yielder|
      @recipient.each do |user|
        yielder << user if @recipient.consented?(user, @consents)
      end
    end.each(&)
  end
end
end

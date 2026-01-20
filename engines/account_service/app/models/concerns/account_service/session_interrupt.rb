# frozen_string_literal: true

module AccountService
module SessionInterrupt # rubocop:disable Layout/IndentationWidth
  def interrupt?
    interrupts.any?
  end

  def interrupts
    @interrupts ||= [
      new_consents,
      new_policy,
    ].compact
  end

  private

  def new_consents
    'new_consents' if Treatment.count > user.consents.count
  end

  def new_policy
    'new_policy' unless user.policy_accepted?
  end
end
end

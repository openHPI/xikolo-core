# frozen_string_literal: true

class UserStepDecorator < Draper::Decorator
  delegate_all

  def as_json(opts = {})
    object.decorate(context:).as_json(opts).merge user_fields
  end

  private

  def user_fields
    {
      state: participant.state_for(object),
      current: current?,
    }
  end

  def participant
    context.fetch :participant
  end

  def current?
    participant.currently_on? object
  end
end

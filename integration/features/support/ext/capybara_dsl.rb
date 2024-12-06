# frozen_string_literal: true

module CDSL
  def within_dialog(&)
    within('[role=dialog][aria-modal=true]', &)
  end
end

Gurke.world.include CDSL

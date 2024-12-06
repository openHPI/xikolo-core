# frozen_string_literal: true

class Helpdesk::TicketForm < XUI::Form
  self.form_name = 'ticket'

  attribute :data, :string

  def categories_for(current_user)
    Helpdesk::CategoryOptions.options_for current_user
  end
end

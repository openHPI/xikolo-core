# frozen_string_literal: true

class ItemGradeController < ApplicationController
  responders Responders::ApiResponder,
    Responders::DecorateResponder

  respond_to :json

  def show
    return head :not_found unless grade

    respond_with grade
  end

  def decorate(resource)
    ItemGradeDecorator.decorate resource
  end

  private

  def grade
    @grade ||= Item.find(item_id).user_grade(user_id)
  end

  def item_id
    params.require(:item_id)
  end

  def user_id
    params.require(:user_id)
  end
end

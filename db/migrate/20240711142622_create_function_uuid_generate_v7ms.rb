# frozen_string_literal: true

class CreateFunctionUUIDGenerateV7ms < ActiveRecord::Migration[6.1]
  def change
    create_function :uuid_generate_v7ms
  end
end

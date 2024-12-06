# frozen_string_literal: true

module Xikolo::Course
  class Result < Acfs::Resource
    service Xikolo::Course::Client,
      path: {
        create: 'items/:item_id/users/:user_id/results',
        read: 'results/:id',
        update: 'results/:id',
        index: nil,
      }

    attribute :id, :uuid
    attribute :item_id, :uuid
    attribute :user_id, :uuid
    attribute :points, :float
  end
end

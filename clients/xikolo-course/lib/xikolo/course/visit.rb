# frozen_string_literal: true

module Xikolo::Course
  class Visit < Acfs::SingletonResource
    service Xikolo::Course::Client, path: '/items/:item_id/users/:user_id/visit'

    attribute :item_id, :uuid
    attribute :user_id, :uuid
  end
end

# frozen_string_literal: true

module Xikolo
  module V2::CollabSpace
    class CollabSpaces < Xikolo::Endpoint::CollectionEndpoint
      entity do
        type 'collab-spaces'

        link('self') {|res| "/api/v2/collab-spaces/#{res['id']}" }
      end
    end
  end
end

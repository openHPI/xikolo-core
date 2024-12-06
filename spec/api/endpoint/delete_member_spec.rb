# frozen_string_literal: true

require 'spec_helper'

# See http://jsonapi.org/format/#crud-deleting
describe 'RESTful deletion of member resources' do
  include Rack::Test::Methods

  def app
    @app ||= Class.new(Xikolo::Endpoint::CollectionEndpoint)
  end

  subject(:response) { delete '/123' }

  before do
    app.entity do
      type 'courses'
      attribute('name') do
        type :string
      end
    end

    blk = delete_block
    app.member do
      delete 'Delete the resource', &blk
    end
  end

  describe 'successful deletion' do
    let(:delete_block) do
      proc {
        # Some code that deletes the resource
      }
    end

    # A server MUST return a 204 No Content status code if a deletion
    # request is successful and no content is returned.
    it 'responds with HTTP 204' do
      expect(response.status).to eq 204
    end
  end

  describe 'when the resource does not exist' do
    let(:delete_block) do
      proc { not_found! }
    end

    # A server SHOULD return a 404 Not Found status code if a deletion
    # request fails due to the resource not existing.
    it 'responds with 404 Not Found' do
      expect(response.status).to eq 404
    end
  end
end

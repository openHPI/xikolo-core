# frozen_string_literal: true

require 'spec_helper'

describe PingController, type: :controller do
  describe 'index' do
    it 'returns the wanted page and answer with HTTP Status 200' do
      get :index
      assert_response :success
    end
  end
end

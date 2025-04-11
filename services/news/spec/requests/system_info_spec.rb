# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'System Info', type: :request do
  subject(:info) { api.rel(:system_info).get({id: -1}).value! }

  let(:api) { Restify.new(:test).get.value! }

  it 'returns a running state' do
    expect(info['running']).to be true
  end

  it 'returns the hostname' do
    expect(info['hostname']).to eq Socket.gethostname
  end
end

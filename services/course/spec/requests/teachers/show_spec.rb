# frozen_string_literal: true

require 'spec_helper'

describe 'Teacher: Show', type: :request do
  subject(:action) { api.rel(:teacher).get({id: teacher.id}).value! }

  let(:teacher) { create(:'course_service/teacher') }
  let(:api) { Restify.new(:test).get.value }

  it 'is successful' do
    expect(action).to respond_with :ok
  end

  it 'responds with teacher resource' do
    expect(action).to eq teacher.decorate.as_json(api_version: 1)
  end
end

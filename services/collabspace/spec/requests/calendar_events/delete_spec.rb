# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Calendar Events: Delete', type: :request do
  subject(:delete_request) { api.rel(:calendar_event).delete({id: event.id}).value! }

  let(:api) { Restify.new(:test).get.value! }
  let!(:event) { create(:calendar_event) }

  it 'the record cannot be loaded anymore' do
    delete_request
    expect { event.reload }.to raise_error(ActiveRecord::RecordNotFound)
  end

  it 'deletes the record' do
    expect { delete_request }.to change { CalendarEvent.all.size }.by(-1)
  end
end

# frozen_string_literal: true

require 'spec_helper'

describe NewsService::Recipient::User, type: :model do
  subject(:recipient) { described_class.new 'the_id' }

  before do
    Stub.service(:account, build(:'account:root'))
    Stub.request(:account, :get, '/users/the_id')
      .to_return Stub.json({id: 'the_id'})
  end

  describe '.each' do
    it 'returns an enumerator' do
      expect(recipient.each).to be_an Enumerator
    end

    it 'yields once' do
      expect {|b| recipient.each(&b) }.to yield_control.once
    end

    it 'enumerator over the user resource' do
      recipient.each.next.tap do |resource|
        aggregate_failures 'resource' do
          expect(resource).to be_a Restify::Resource
          expect(resource.data).to include 'id' => 'the_id'
        end
      end
    end
  end
end

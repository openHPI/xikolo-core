# frozen_string_literal: true

require 'spec_helper'
require 'csv'

Rails.application.load_tasks if Rake::Task.tasks.empty?

describe 'batch enrollment rake task' do
  context 'users_csv:get_users' do
    subject(:task) { Rake::Task['users_csv:get_users'].invoke }

    let(:known_email) { {address: 'kevin.cool@example.com', user_id: generate(:user_id)} }

    let(:unknown_email_list) { ['admin@example.com', 'tom@example.com', 'conrad@example.com'] }

    around do |example|
      ENV['CSV'] = 'spec/fixtures/files/batch_test_mails.csv'
      example.run
    ensure
      ENV['CSV'] = ''
    end

    before do
      Stub.service(:account, build(:'account:root'))
      unknown_email_list.each do |email|
        Stub.request(:account, :get, "/emails/#{email}").to_return(status: 404)
      end
      Stub.request(:account, :get, "/emails/#{known_email[:address]}").and_return Stub.json(known_email)
    end

    it 'takes csv file containing users email addresses and returns csv file with email addresses and user ids' do
      task
      expect(CSV.open('/tmp/users.csv').read).to eq [['User ID', 'Email'], [known_email[:user_id], known_email[:address]]]
    end
  end
end

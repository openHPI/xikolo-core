# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Polls: Archive', type: :request do
  subject(:archive) { get '/polls/archive', headers: }

  let(:headers) { {'Authorization' => "Xikolo-Session session_id=#{stub_session_id}"} }

  before do
    stub_user_request

    create(:poll,
      question: 'Which of these course elements do you use regularly?',
      start_at: DateTime.new(2021, 2, 2, 12, 13, 1),
      end_at: DateTime.new(2021, 3, 2, 12, 13, 1))
  end

  it 'shows polls result without participants correctly' do
    archive

    expect(response.body).to include('Which of these course elements do you use regularly?')
    expect(response.body).to include('Poll ended on Mar 02, 2021 with 0 participants.')
  end
end

# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Rubric: Delete', type: :request do
  subject(:deletion) { api.rel(:rubric).delete(id: rubric.id).value! }

  let(:api) { Restify.new(:test).get.value! }
  let!(:rubric) { create(:rubric) }
  let(:params) { {title: 'Important Rubric'} }

  it { is_expected.to respond_with :no_content }

  it 'deletes the rubric' do
    expect { deletion }.to change(Rubric, :count).from(1).to(0)
  end

  context 'with old file references' do
    let(:rubric) { create(:rubric, hints: "Headline\ns3://xikolo-peerassessment/peerassessments/1/rubrics/2/rtfiles/3/test.pdf") }
    let(:params) { super().merge hints: "Headline\nNo content" }

    it 'deletes no-longer referenced files' do
      cleanup_stub = stub_request(
        :delete,
        'https://s3.xikolo.de/xikolo-peerassessment/peerassessments/1/rubrics/2/rtfiles/3/test.pdf'
      ).and_return(status: 200)

      deletion
      expect(cleanup_stub).to have_been_requested
    end
  end
end

# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Root', type: :request do
  subject { restify_with_headers(pinboard_service_url).get.value! }

  it { is_expected.to have_rel :post }
  it { is_expected.to have_rel :topics }
  it { is_expected.to have_rel :topic }
end

# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Root', type: :request do
  subject { Restify.new(:test).get.value! }

  it { is_expected.to have_rel :post }
  it { is_expected.to have_rel :topics }
  it { is_expected.to have_rel :topic }
end

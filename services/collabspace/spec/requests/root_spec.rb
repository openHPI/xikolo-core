# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Root', type: :request do
  subject { Restify.new(:test).get.value! }

  it { is_expected.to have_rel :collab_spaces }
  it { is_expected.to have_rel :collab_space }
  it { is_expected.to have_rel :memberships }
  it { is_expected.to have_rel :membership }

  it { is_expected.to have_rel :system_info }

  # @deprecated Old relation names
  it { is_expected.to have_rel :learning_rooms }
  it { is_expected.to have_rel :learning_room }
end

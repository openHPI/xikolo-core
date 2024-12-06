# frozen_string_literal: true

require 'spec_helper'

describe RootController, type: :controller do
  subject { resource }

  let(:resource) { Restify.new(:test).get.value! }

  it { is_expected.to have_relation :user_tests }
  it { is_expected.to have_relation :user_test }
  it { is_expected.to have_relation :trials }
  it { is_expected.to have_relation :trial }
  it { is_expected.to have_relation :test_groups }
  it { is_expected.to have_relation :test_group }
  it { is_expected.to have_relation :metrics }
  it { is_expected.to have_relation :metric }
  it { is_expected.to have_relation :filters }
  it { is_expected.to have_relation :filter }
  it { is_expected.to have_relation :user_assignments }
  it { is_expected.to have_relation :system_info }
end

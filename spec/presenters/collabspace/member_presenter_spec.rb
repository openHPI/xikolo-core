# frozen_string_literal: true

require 'spec_helper'

describe Collabspace::MemberPresenter do
  subject { described_class.new user:, membership: }

  let(:user) { instance_double Xikolo::Account::User, id: user_id, name: }
  let(:user_id) { SecureRandom.uuid }
  let(:name) { 'Kevin Cool' }
  let(:membership) { {'user_id' => user_id, 'status' => status} }
  let(:status) { 'regular' }

  its(:id) { is_expected.to eq user_id }
  its(:name) { is_expected.to eq name }
  its(:status) { is_expected.to eq status }
  its(:display) { is_expected.to eq name }

  context 'with non-regular status' do
    let(:status) { 'admin' }

    its(:display) { is_expected.to eq "#{name} (Admin)" }
  end
end

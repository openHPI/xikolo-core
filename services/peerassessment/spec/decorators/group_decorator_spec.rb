# frozen_string_literal: true

require 'spec_helper'

describe GroupDecorator, type: :decorator do
  let(:decorator) { GroupDecorator.new create(:group, :with_participants) }

  context 'as_api_v1' do
    subject { json }

    let(:json) { decorator.as_json(api_version: 1).stringify_keys }

    it { is_expected.to include('id') }
    it { is_expected.to include('participants') }
    its(['participants']) { is_expected.to have(5).items }
  end
end

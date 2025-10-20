# frozen_string_literal: true

require 'spec_helper'

describe ClassifierDecorator do
  subject(:json) { decorator.as_json(api_version: 1).stringify_keys }

  let(:classifier) { create(:'course_service/classifier') }
  let(:decorator) { described_class.new(classifier) }

  it { is_expected.to include('id') }
  it { is_expected.to include('title') }
  it { is_expected.to include('url') }
  it { is_expected.to include('cluster') }
end

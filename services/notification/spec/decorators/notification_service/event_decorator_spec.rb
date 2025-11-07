# frozen_string_literal: true

require 'spec_helper'

describe NotificationService::EventDecorator, type: :decorator do
  subject { json }

  let(:event) { create(:'notification_service/event') }
  let(:decorator) { NotificationService::EventDecorator.new(event) }
  let(:json) { decorator.as_json(api_version: 1).stringify_keys }

  it { is_expected.to include('id') }
  it { is_expected.to include('key') }
  it { is_expected.to include('payload') }
  it { is_expected.to include('text') }
  it { is_expected.to include('title') }
  it { is_expected.to include('link') }
  it { is_expected.to include('course_id') }
  it { is_expected.to include('course_name') }
end

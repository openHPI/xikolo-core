# frozen_string_literal: true

require 'spec_helper'

describe Catalog::Course, '.status', type: :model do
  subject { described_class.new(published:, start_date:, end_date:).status }

  context 'for a course in preparation' do
    let(:published) { false }
    let(:start_date) { nil }
    let(:end_date) { nil }

    it { is_expected.to eq('preparation') }
  end

  context 'for an active course' do
    let(:published) { true }
    let(:start_date) { 2.days.ago }
    let(:end_date) { 2.days.from_now }

    it { is_expected.to eq('active') }
  end

  context 'for a self-paced course with past end date' do
    let(:published) { true }
    let(:start_date) { nil }
    let(:end_date) { 2.days.ago }

    it { is_expected.to eq('self-paced') }
  end

  context 'for a self-paced course with no end date' do
    let(:published) { true }
    let(:start_date) { nil }
    let(:end_date) { nil }

    it { is_expected.to eq('active') }
  end

  context 'for a self-paced course with end date in the future' do
    let(:published) { true }
    let(:start_date) { nil }
    let(:end_date) { 2.days.from_now }

    it { is_expected.to eq('active') }
  end

  context 'for an upcoming course' do
    let(:published) { true }
    let(:start_date) { 2.days.from_now }
    let(:end_date) { 2.days.from_now + 1.year }

    it { is_expected.to eq('upcoming') }
  end

  context 'for a self-paced course with past start and end date' do
    let(:published) { true }
    let(:start_date) { 2.days.ago }
    let(:end_date) { 1.day.ago }

    it { is_expected.to eq('self-paced') }
  end

  context 'for a course with past start date, future end date' do
    let(:published) { true }
    let(:start_date) { 2.days.ago }
    let(:end_date) { 1.day.from_now }

    it { is_expected.to eq('active') }
  end

  context 'for a course with past start date and no end date' do
    let(:published) { true }
    let(:start_date) { 2.days.ago }
    let(:end_date) { nil }

    it { is_expected.to eq('self-paced') }
  end
end

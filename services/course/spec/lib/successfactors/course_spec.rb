# frozen_string_literal: true

require 'spec_helper'

describe Successfactors::Course do
  let(:course_attrs) { attributes_for(:course, :active) }
  let(:course) { create(:course, course_attrs) }

  let(:provider_config) do
    attributes_for(:course_provider, :successfactors)[:config]
      .stringify_keys
  end

  let(:sf_course) { described_class.new course, provider_config }

  # prevent callback on course creation through FactoryBot
  before { allow_any_instance_of(Course).to receive(:sync_providers) } # rubocop:disable RSpec/AnyInstance

  describe '#as_ocn_data' do
    subject(:ocn_data) { sf_course.as_ocn_data }

    context 'with hidden course' do
      let(:course_attrs) { attributes_for(:course, :active, hidden: true) }

      it 'is marked as inactive' do
        expect(ocn_data[:schedule].first[:active]).to be_falsey
        expect(ocn_data[:status]).to eq 'INACTIVE'
      end
    end

    context 'with course in preparation' do
      let(:course_attrs) { attributes_for(:course, :active, status: 'preparation') }

      it 'is marked as inactive' do
        expect(ocn_data[:schedule].first[:active]).to be_falsey
        expect(ocn_data[:status]).to eq 'INACTIVE'
      end
    end

    context 'with deleted course' do
      let(:course_attrs) do
        attributes_for(
          :course,
          :active,
          deleted: true,
          course_code: 'the-course-deleted-123'
        )
      end

      it 'is marked as inactive' do
        expect(ocn_data[:schedule].first[:active]).to be_falsey
        expect(ocn_data[:status]).to eq 'INACTIVE'
      end

      it 'has the original course_code' do
        expect(ocn_data[:courseID]).to eq 'the-course'
      end
    end
  end
end

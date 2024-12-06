# frozen_string_literal: true

require 'spec_helper'

describe Course::Metadata, type: :model do
  describe '(validations)' do
    describe 'skills' do
      subject(:metadata) do
        course = create(:course)
        described_class.new(course_id: course.id, name: 'skills', version: 'urn:moochub:3.0')
      end

      let(:valid_skills_data) do
        JSON.parse(File.read('spec/support/files/course/metadata/skills_valid.json'))
      end
      let(:invalid_skills_data) do
        JSON.parse(File.read('spec/support/files/course/metadata/skills_invalid.json'))
      end

      it { is_expected.to accept_values_for(:data, valid_skills_data) }

      context 'with invalid skills JSON data' do
        it 'raises a validation error according to the JSON schema' do
          expect { metadata.update!(data: invalid_skills_data) }.to raise_error(JSON::Schema::ValidationError)
        end
      end
    end

    describe 'educational alignment' do
      subject(:metadata) do
        course = create(:course)
        described_class.new(course_id: course.id, name: 'educational_alignment', version: 'urn:moochub:3.0')
      end

      let(:valid_educational_alignment_data) do
        JSON.parse(File.read('spec/support/files/course/metadata/educational_alignment_valid.json'))
      end
      let(:invalid_educational_alignment_data) do
        JSON.parse(File.read('spec/support/files/course/metadata/educational_alignment_invalid.json'))
      end

      it { is_expected.to accept_values_for(:data, valid_educational_alignment_data) }

      context 'with invalid educational alignment JSON data' do
        it 'raises a validation error according to the JSON schema' do
          expect { metadata.update!(data: invalid_educational_alignment_data) }.to raise_error(JSON::Schema::ValidationError)
        end
      end
    end
  end
end

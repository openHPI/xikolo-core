# frozen_string_literal: true

require 'spec_helper'

describe Certificate::Template, type: :model do
  let(:template) { create(:certificate_template, :fixed) }

  describe '(validations)' do
    describe 'unique for course' do
      subject(:duplicate_template) do
        build(:certificate_template, :fixed)
      end

      before { template }

      it 'does not allow two templates for the same type for a course' do
        expect(duplicate_template).not_to be_valid
      end
    end

    describe 'allowed types only' do
      subject(:template) { build(:certificate_template, :fixed, certificate_type:) }

      before do
        xi_config <<~YML
          certificate:
            transcript_of_records:
              table_x: 200
              table_y: 500
              course_col_width: 300
              score_col_width: 70
              font_size: 10
        YML
      end

      context 'with existing RoA' do
        let(:certificate_type) { 'TranscriptOfRecords' }

        before { create(:certificate_template, :fixed) }

        it 'does not allow creation of a ToR' do
          expect(template).not_to be_valid
        end

        context 'other type' do
          let(:certificate_type) { 'ConfirmationOfParticipation' }

          it 'allows creation of a CoP' do
            expect(template).to be_valid
          end
        end
      end

      context 'with existing ToR' do
        let(:certificate_type) { 'RecordOfAchievement' }

        before { create(:certificate_template, :fixed, :tor) }

        it 'does not allow creation of a RoA' do
          expect(template).not_to be_valid
        end
      end
    end

    describe 'dynamic content' do
      context 'with valid XML' do
        subject(:template) { build(:certificate_template) }

        it 'allows the template to be saved' do
          expect(template).to be_valid
        end
      end

      context 'with invalid XML' do
        subject(:template) { build(:certificate_template, :invalid_xml) }

        it 'does not allow the template to be saved' do
          expect(template).not_to be_valid
          expect(template.errors.full_messages.join(',')).to include('The XML for the dynamic content is invalid')
        end
      end

      context 'using fonts not present in the config' do
        subject(:template) { build(:certificate_template, :missing_fonts) }

        it 'does not allow the template to be saved' do
          expect(template).not_to be_valid
          expect(template.errors.full_messages.join(',')).to include('Font/s not supported: NeoSansMedium. Supported fonts are OpenSansRegular, OpenSansSemibold')
        end
      end

      context 'with invalid schema' do
        subject(:template) { build(:certificate_template, :invalid_schema) }

        it 'does not allow the template to be saved' do
          expect(template).not_to be_valid
          expect(template.errors.full_messages.join(',')).to include("The attribute 'font' is not allowed")
          expect(template.errors.full_messages.join(',')).to include("The value 'left' is not an element of the set {'start', 'middle', 'end', 'inherit'}")
        end
      end
    end
  end

  describe '#allowed_types' do
    subject(:allowed_types) { new_template.allowed_types }

    let(:new_template) { Certificate::Template.new(course:) }
    let(:course) { create(:course) }

    before do
      xi_config <<~YML
        certificate:
          transcript_of_records:
            table_x: 200
            table_y: 500
            course_col_width: 300
            score_col_width: 70
            font_size: 10
      YML
    end

    it 'has all types' do
      expect(allowed_types).to eq(
        %i[
          ConfirmationOfParticipation
          RecordOfAchievement
          Certificate
          TranscriptOfRecords
        ]
      )
    end

    context 'with existing Transcript of Records template' do
      before { create(:certificate_template, :tor, course:) }

      it 'only has Transcript of Records' do
        expect(allowed_types).to eq(%i[TranscriptOfRecords])
      end
    end

    context 'with existing RoA template' do
      before { create(:certificate_template, :roa, course:) }

      it 'has no Transcript of Records' do
        expect(allowed_types).to eq(
          %i[
            ConfirmationOfParticipation
            RecordOfAchievement
            Certificate
          ]
        )
      end
    end

    context 'without Transcript of Records config' do
      before do
        xi_config <<~YML
          certificate:
            transcript_of_records: ~
        YML
      end

      it 'has no Transcript of Records' do
        expect(allowed_types).to eq(
          %i[
            ConfirmationOfParticipation
            RecordOfAchievement
            Certificate
          ]
        )
      end
    end
  end
end

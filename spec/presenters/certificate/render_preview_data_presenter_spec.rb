# frozen_string_literal: true

require 'spec_helper'

describe Certificate::RenderPreviewDataPresenter, type: :presenter do
  subject(:render_preview_data) { described_class.new record, template }

  let(:record) { Certificate::PreviewRecord.new(template, user) }
  let(:template) do
    create(
      :certificate_template, :roa,
      dynamic_content:,
      qrcode_x: 200,
      qrcode_y: 100
    )
  end
  let(:dynamic_content) do
    <<~DYNCONTENT
      <?xml version 1.0 encoding="utf-8"?>
      <svg xmlns="http://www.w3.org/2000/svg">
        <text id='name'>##NAME##</text>
        <text>##EMAIL##</text>
        <text>##EMAIL_V2##</text>
        <text>##GRADE##</text>
        <text>##GRADE_V2##</text>
        <text>##GRADE_V3##</text>
        <text>##BIRTHDAY##</text>
        <text>##BIRTHDAY_V2##</text>
        <text>##BIRTHDAY_V3##</text>
        <text>##BIRTHDAY_INTL##</text>
        <text>##TOP##</text>
        <text>##TOP_V2##</text>
        <text>##VERIFY##</text>
        <text>##ISSUED_AT##</text>
        <text>##ISSUED_AT_INTL##</text>
      </svg>
    DYNCONTENT
  end
  let(:user) { create(:user, :with_email) }
  let(:enrollment) { create(:enrollment, user_id: user.id, course:) }

  before do
    xi_config <<~YML
      certificate:
        forbidden_verification_words: ['forbidden']
        transcript_of_records:
          table_x: 200
          table_y: 500
          course_col_width: 300
          score_col_width: 70
          font_size: 10
    YML
  end

  describe '#dynamic_content' do
    subject(:dynamic_content_data) do
      Nokogiri::XML(render_preview_data.dynamic_content).search('text').map(&:content)
    end

    around {|example| I18n.with_locale(:en, &example) }

    context 'points' do
      subject(:points_data) { dynamic_content_data[3..5] }

      it 'has the correct points subsitutes' do
        expect(points_data).to eq [
          '94.6 out of 100 possible points (94.6%)',
          ' 94.6 points (94.6%) ',
          '94.6 / 100 points (94.6%)',
        ]
      end
    end

    context 'top' do
      subject(:top_data) { dynamic_content_data[10..11] }

      it 'has the correct top substitutes' do
        expect(top_data).to eq [
          'Is part of the top 5% active course participants.',
          'The candidate belongs to the top 5% of the course participants.',
        ]
      end
    end

    context 'issued_at' do
      subject(:issued_at_data) { dynamic_content_data[13..14] }

      around do |example|
        date = Date.new(2018, 1, 1)
        Timecop.freeze(date) { example.run }
      end

      it 'has the correct issued_at substitutes' do
        expect(issued_at_data).to eq [
          'January 1, 2018',
          '1. Januar 2018',
        ]
      end
    end
  end

  describe '#qrcode_url' do
    subject(:qrcode_data) { render_preview_data.qrcode_url }

    it { is_expected.to eq 'https://xikolo.de/verify/jazzy-fuzzy-juicy-junky-pizza' }
  end

  describe '#proctoring_image' do
    subject(:proctoring_data) { render_preview_data.proctoring_image }

    context 'with certificate' do
      let(:template) do
        create(
          :certificate_template, :certificate,
          dynamic_content:,
          qrcode_x: 200,
          qrcode_y: 100
        )
      end
      let(:enrollment) { create(:enrollment, :proctored, user_id: user.id, course:) }

      it 'uses the static sample image' do
        expect(File).to exist proctoring_data
        expect(proctoring_data.to_s).to match 'assets/images/certificate/user_certificate_image.jpg'
      end
    end
  end

  describe '#transcript_of_records' do
    subject(:tor) { render_preview_data.transcript_of_records }

    it 'is empty for other certificate types' do
      expect(tor).to be_nil
    end

    context '(for TranscriptOfRecords)' do
      let(:template) { create(:certificate_template, :tor) }

      it do
        expect(tor).to eq(
          [
            ['Course', 'Score'],
            ['Geovisualisierung', 'passed'],
            ['Internet-Technologien', '100.0%'],
            ['Sicherheit im Internet', '50.0%'],
            ['Overall score', '75.0%'],
          ]
        )
      end
    end
  end
end

# frozen_string_literal: true

require 'spec_helper'

describe Certificate::RecordRenderer do
  subject(:pdf_content) do
    PDF::Inspector::Text.analyze(described_class.as_pdf(data)).strings.join(' ')
  end

  let(:data) do
    instance_double(Certificate::RenderDataPresenter,
      template_path:,
      dynamic_content:,
      qrcode_pos: {x: 100, y: 100},
      proctoring_image: Rails.root.join('spec', 'support', 'files', 'proctoring', 'user_certificate_image.jpg'),
      qrcode_url: 'http://qrcode_url',
      transcript_of_records:)
  end
  let(:template_path) { Rails.root.join('spec', 'support', 'files', 'certificate', 'template.pdf') }
  let(:dynamic_content) do
    <<~DYN_CONTENT
      <?xml version="1.0" encoding="utf-8"?>
      <!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1 Basic//EN" "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11-basic.dtd">
      <svg version="1.1" baseProfile="basic" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" x="0px" y="0px" width="842" height="595" viewBox="0 0 842 595" xml:space="preserve">
        <g id="Dynamic data">
          <text fill="#C82B4A" stroke="#C82B4A" stroke-width="0" x="128.90" y="153.04" font-size="21.6" font-family="NeoSansMedium" text-anchor="left" xml:space="preserve">DYNAMIC_CONTENT</text>
        </g>
      </svg>
    DYN_CONTENT
  end
  let(:transcript_of_records) { nil }

  describe '.as_pdf' do
    it 'renders the dynamic content' do
      expect(pdf_content).to include 'DYNAMIC_CONTENT'
    end

    it 'uses the template file' do
      expect(pdf_content).to include 'Weske'
    end

    context 'for Transcript of Records' do
      let(:transcript_of_records) do
        [
          ['Course', 'Score'],
          ['Internet Security', '60.0%'],
          ['Overall score', '60.0%'],
        ]
      end

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

      it 'renders the transcript table' do
        expect(pdf_content).to include('Course Score Internet Security 60.0% Overall score 60.0%')
      end
    end
  end

  describe 'RecordPdf#fonts' do
    subject(:fonts) do
      Certificate::RecordRenderer::RecordPdf.new(data).send(:fonts)
    end

    context 'without font configuration' do
      before do
        xi_config <<~YML
          certificate:
            fonts: ~
        YML
      end

      it 'uses the default fonts' do
        expect(fonts).to eq(
          {
            'OpenSansRegular' => "#{Rails.root}/app/assets/fonts/OpenSans-Regular.ttf",
            'OpenSansSemibold' => "#{Rails.root}/app/assets/fonts/OpenSans-Semibold.ttf",
          }
        )
      end
    end

    context 'with custom font configuration' do
      before do
        xi_config <<~YML
          brand: the-brand
          certificate:
            fonts:
              ComicSans: comic_sans.ttf
              ComicSansBold: comic_sans_bold.ttf
        YML
      end

      after do
        xi_config <<~YML
          brand: xikolo
        YML
      end

      it 'uses the configured fonts from the brand directory' do
        expect(fonts).to eq(
          {
            'ComicSans' => "#{Rails.root}/brand/the-brand/assets/fonts/comic_sans.ttf",
            'ComicSansBold' => "#{Rails.root}/brand/the-brand/assets/fonts/comic_sans_bold.ttf",
          }
        )
      end
    end
  end
end

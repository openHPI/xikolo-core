# frozen_string_literal: true

require 'spec_helper'

describe Certificate::RenderDataPresenter, type: :presenter do
  subject(:render_data) { described_class.new record, template }

  let(:course) { create(:course, records_released: true, lang: 'en', start_date: '1977-06-01', end_date: '1977-06-07') }
  let(:record) { create(:roa, user:, course:, template:) }
  let(:template) do
    create(:certificate_template, :roa,
      course:,
      file_uri:,
      dynamic_content:,
      qrcode_x: 200,
      qrcode_y: 100)
  end
  let(:file_uri) { 's3://certificate/templates/234.pdf' }
  let(:dynamic_content) do
    <<~DYNCONTENT
      <?xml version="1.0" encoding="utf-8"?>
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
  let(:user) do
    account_user = create(:'account_service/user',
      full_name: user_fullname,
      born_at: '1960-01-02',
      preferences: {'records.show_birthdate' => show_birthdate})
    account_user.primary_email.update!(address: 'jane.doe@example.com')
    AccountService::User.find(account_user.id)
  end
  let(:user_fullname) { 'Jane Doe' }
  let(:show_birthdate) { true }
  let(:quantile) { 0.50 }
  let(:certificates) do
    {
      record_of_achievement: true,
      confirmation_of_participation: true,
      certificate: false,
    }
  end
  let(:enrollment_with_evaluation) do
    create(
      :'course_service/enrollment',
      :with_evaluation,
      course_id: course.id,
      quantiled_user_dpoints: 50,
      user_id: user.id,
      completed: true,
      quantile:,
      deleted: false
    )
  end

  before do
    enrollment_with_evaluation
  end

  describe '#template_path' do
    let(:file_uri) { 's3://certificate/templates/234_v1.pdf' }
    let(:download_stub) do
      stub_request(
        :get,
        "#{test_s3_host}/certificate/templates/234_v1.pdf"
      ).and_return(status: 200, body: 'example-template')
    end

    before { download_stub }

    it 'provides the template content via temporary file' do
      expect(render_data.template_path).to include '/certtmpl'
      expect(download_stub).to have_been_requested
      expect(File.read(render_data.template_path)).to eq 'example-template'
    end
  end

  describe '#dynamic_content' do
    subject(:dynamic_content_data) do
      Nokogiri::XML(render_data.dynamic_content).search('text').map(&:content)
    end

    around {|example| I18n.with_locale(:en, &example) }

    it 'substitutes the correct values' do
      expect(dynamic_content_data).to eq [
        'Jane Doe',
        'jane.doe@example.com',
        'E-mail: jane.doe@example.com',
        '8.0 out of 10.0 possible points (80.0%)',
        ' 8.0 points (80.0%) ',
        '8.0 / 10.0 points (80.0%)',
        'born on: January 2, 1960',
        'Date of birth: January 2, 1960',
        'January 2, 1960',
        '2. Januar 1960',
        '',
        '',
        "Verify online: https://xikolo.de/verify/#{record.verification}",
        'June 7, 1977',
        '7. Juni 1977',
      ]
    end

    context 'without birthdate' do
      subject(:birthdate_data) { dynamic_content_data[6..9].uniq }

      let(:show_birthdate) { false }

      it { is_expected.to eq [''] }
    end

    context 'with top' do
      subject(:top_data) { dynamic_content_data[10..11] }

      context 'with top 5' do
        let(:quantile) { 0.99 }

        it 'has the correct top substitutes' do
          expect(top_data).to eq [
            'Is part of the top 5% active course participants.',
            'The candidate belongs to the top 5% of the course participants.',
          ]
        end
      end

      context 'with top 10' do
        let(:quantile) { 0.92 }

        it 'has the correct top substitutes' do
          expect(top_data).to eq [
            'Is part of the top 10% active course participants.',
            'The candidate belongs to the top 10% of the course participants.',
          ]
        end
      end

      context 'with top 20' do
        let(:quantile) { 0.85 }

        it 'has the correct top substitutes' do
          expect(top_data).to eq [
            'Is part of the top 20% active course participants.',
            'The candidate belongs to the top 20% of the course participants.',
          ]
        end
      end

      context 'out of top' do
        let(:quantile) { 0.09 }

        it 'has the correct top substitutes' do
          expect(top_data).to eq ['', '']
        end
      end

      context 'with Arabic name' do
        subject(:name_element) do
          Nokogiri::XML(render_data.dynamic_content).at_css('[id="name"]')
        end

        let(:user_fullname) { 'مطور خبير' }

        it 'is attributed with right-to-left direction' do
          expect(name_element['direction']).to eq 'rtl'
        end
      end

      context 'with special character (ampersand) in name' do
        subject(:name_element) do
          Nokogiri::XML(render_data.dynamic_content).at_css('[id="name"]')
        end

        let(:user_fullname) { 'Fest & Flauschig' }

        it 'preserves the ampersand' do
          expect(name_element.content).to eq 'Fest & Flauschig'
        end

        it 'wraps the name in CDATA' do
          expect(name_element.children.first).to be_cdata
        end
      end
    end

    context 'with course language that is not in available locales' do
      subject(:mail_data) { dynamic_content_data[2] }

      let(:course) { create(:course, records_released: true, lang: 'aaa') }

      it 'falls back to the default locale (english)' do
        expect(mail_data).to eq 'E-mail: jane.doe@example.com'
      end
    end
  end

  describe '#qrcode_url' do
    it 'has the correct qrcode url' do
      expect(render_data.qrcode_url).to eq "https://xikolo.de/verify/#{record.verification}"
    end

    it 'has the correct qrcode position' do
      expect(render_data.qrcode_pos).to eq(x: 200, y: 100)
    end
  end

  describe '#issue_date' do
    it 'is the completed_at date' do
      expect(render_data.issue_date).to eq Date.new(1977, 6, 7)
    end

    context 'fallback to course end date' do
      let(:completed_at) { nil }

      it 'is the course end date' do
        expect(render_data.issue_date).to eq course.end_date&.to_date
      end

      context 'without an enrollment' do
        before { allow(record).to receive(:enrollment).and_return(nil) }

        it 'is the course end date' do
          expect(render_data.issue_date).to eq course.end_date&.to_date
        end
      end
    end

    context 'fallback to now, if course has no end date' do
      let(:course) do
        create(:course, records_released: true, lang: 'en', end_date: nil)
      end
      let(:completed_at) { nil }

      around {|example| Timecop.freeze(&example) }

      it 'is today' do
        expect(render_data.issue_date).to eq Time.zone.today
      end
    end

    context 'with a Confirmation of Participation' do
      let(:record) { create(:cop, user:, course:, template:) }
      let(:template) do
        create(:certificate_template, :cop,
          course:,
          file_uri:,
          dynamic_content:,
          qrcode_x: 200,
          qrcode_y: 100)
      end

      it 'shows todays date as the issue date' do
        expect(render_data.issue_date).to eq Time.zone.now.to_date
      end
    end
  end
end

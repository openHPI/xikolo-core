# frozen_string_literal: true

require 'spec_helper'

describe Certificate::RecordPresenter, type: :presenter do
  subject(:presented_record) { described_class.new record, :verify }

  let(:record) { create(:roa, user:, course:, template:) }
  let(:template) { create(:certificate_template, :roa, course:) }
  let(:course) { create(:course, course_params) }
  let(:course_params) do
    {
      records_released: true,
      start_date: nil,
      end_date: nil,
      roa_threshold_percentage: 65,
      cop_threshold_percentage: 55,
    }
  end
  let(:user) do
    create(:user,
      born_at: birthday,
      preferences: {'records.show_birthdate' => true})
  end
  let(:birthday) { '1960-01-02' }
  let(:certificates) do
    {
      record_of_achievement: true,
      confirmation_of_participation: true,
      certificate: true,
    }
  end
  let(:enrollment) { create(:enrollment, user_id: user.id, course:) }
  let(:enrollments) do
    build_list(
      :'course:enrollment', 1,
      course_id: enrollment.course_id,
      user_id: enrollment.user_id,
      points: {achieved: 50, maximal: 100, percentage: 18},
      certificates:,
      quantile: 0.9,
      completed_at: Time.new(1977, 6, 7, 9, 0, 0).utc
    )
  end

  before do
    Stub.service(:course, build(:'course:root'))
    Stub.request(
      :course, :get, '/enrollments',
      query: hash_including(
        course_id: enrollment.course_id,
        user_id: enrollment.user_id,
        learning_evaluation: 'true'
      )
    ).to_return Stub.json(enrollments)
  end

  describe '(values for purpose)' do
    it 'accepts the allowed values' do
      expect { described_class.new record, :verify }.not_to raise_error
      expect { described_class.new record, :show }.not_to raise_error
    end

    it 'only accepts symbolized values' do
      expect { described_class.new record, 'verify' }.to raise_error(ArgumentError, 'Must be a symbol: purpose')
    end

    it 'rejects other purposes' do
      expect { described_class.new record, :delete }.to raise_error(ArgumentError, 'Unknown purpose: :delete')
    end
  end

  describe '#date_of_birth' do
    context 'with a date of birth' do
      it 'returns the date of birth' do
        expect(presented_record.date_of_birth).to eq birthday
      end
    end

    context 'without a date of birth' do
      let(:birthday) { nil }

      it 'returns nothing' do
        expect(presented_record.date_of_birth).to be_nil
      end
    end
  end

  describe '#course_dates' do
    context 'without an end date' do
      let(:course_params) do
        super().merge(start_date: Time.new(2012, 11, 5, 9, 0, 0).utc)
      end

      it 'shows the start date' do
        expect(presented_record.course_dates).to eq 'since Nov 05, 2012'
      end
    end

    context 'with both dates present' do
      let(:course_params) do
        super().merge(
          start_date: Time.new(2012, 11, 5, 9, 0, 0).utc,
          end_date: Time.new(2012, 12, 21, 20, 0, 0).utc
        )
      end

      it 'shows the date range' do
        expect(presented_record.course_dates).to eq 'Nov 05, 2012 to Dec 21, 2012'
      end
    end
  end

  describe '#certificate_type_i18n' do
    context 'with a RecordOfAchievement' do
      it 'returns the readable type' do
        expect(presented_record.certificate_type_i18n).to eq 'Record of Achievement'
      end
    end

    context 'with a ConfirmationOfParticipation' do
      let(:record) { create(:cop, user:, course:) }

      it 'returns the readable type' do
        expect(presented_record.certificate_type_i18n).to eq 'Confirmation of Participation'
      end
    end

    context 'with a Certificate' do
      let(:record) { create(:certificate, user:, course:) }

      it 'returns the readable type' do
        expect(presented_record.certificate_type_i18n).to eq 'Certificate'
      end
    end
  end

  describe '#certificate_requirements' do
    context 'with a RecordOfAchievement' do
      it 'returns the requirements' do
        expect(presented_record.certificate_requirements).to eq \
          'Gain a <b>Record of Achievement</b> by earning at least <b>65%</b> of the maximum number of points from all graded assignments.'
      end
    end

    context 'with a Certificate' do
      let(:record) { create(:certificate, user:, course:) }

      it 'returns no requirements' do
        expect(presented_record.certificate_requirements).to eq ''
      end
    end

    context 'with a ConfirmationOfParticipation' do
      let(:record) { create(:cop, user:, course:) }

      it 'returns no requirements' do
        expect(presented_record.certificate_requirements).to eq ''
      end
    end
  end

  describe '#score' do
    context 'with a score' do
      it 'displays the score' do
        expect(presented_record.score).to eq '50.0 of 100.0 points (18.0%)'
      end
    end

    context 'without a score' do
      let(:record) { create(:cop, user:, course:) }

      it 'returns nothing' do
        expect(presented_record.score).to be_nil
      end
    end
  end

  describe '#issued_at' do
    it 'returns the formatted date' do
      expect(presented_record.issued_at).to eq '1977-06-07'
    end
  end

  describe '#issued_month' do
    it 'returns the month' do
      expect(presented_record.issued_month).to eq 6
    end
  end

  describe '#issued_year' do
    it 'returns year' do
      expect(presented_record.issued_year).to eq 1977
    end
  end

  describe '#top' do
    it 'returns the top percentage' do
      expect(presented_record.top).to eq 'The result belongs to the <b>top 10%</b> of this course.'
    end
  end

  describe '#additional_records' do
    context 'without additional records' do
      it 'returns nothing' do
        expect(presented_record.additional_records).to be_nil
      end
    end

    context 'with an additional record' do
      let(:code) { 'xinif-mehon-nuhuh-lirom-bapal' }
      let(:record) { create(:roa, verification: code, user:, course:, template:) }

      before { create(:cop, verification: code, user:, course:) }

      it 'returns information about other records' do
        expect(presented_record.additional_records).to eq \
          'The user has also achieved the following record type(s) in this course: <b>Confirmation of Participation</b>. In this case, we always show the verification result for the most valuable record.'
      end
    end
  end
end

# frozen_string_literal: true

require 'spec_helper'

describe 'Achievements: Index', type: :request do
  let(:api) { Restify.new(:test).get.value! }
  let(:course) { create(:course, :active, course_params) }
  let(:course_params) { {cop_enabled: true, roa_enabled: true, on_demand: false} }
  let!(:item) { create(:item, :homework, :with_max_points, item_params) }
  let(:item_params) { {section: create(:section, course:)} }

  let(:user_id) { generate(:user_id) }
  let(:params) { {user_id:} }
  let(:opts) { {headers: {'Accept-Language' => 'en'}} }

  let(:json) { JSON.parse request.response.body }

  let(:request) do
    api
      .rel(:course).get({id: course.id}).value!
      .rel(:achievements).get(params, **opts).value!
  end

  it { expect(request.response).to be_success }
  it { expect(request.response.headers['CONTENT_LANGUAGE']).to eq('en') }

  shared_examples_for 'achieved' do
    it { expect(achievement).to include('achieved' => true, 'achievable' => false) }
  end

  shared_examples_for 'achievable' do
    it do
      expect(achievement).to include('achieved' => false, 'achievable' => true)
      expect(achievement['download']).to include(
        'type' => 'progress',
        'url' => "https://xikolo.de/courses/#{course.course_code}/progress"
      )
    end
  end

  shared_examples_for 'unachievable' do
    it { expect(achievement).to include('achieved' => false, 'achievable' => false) }
  end

  shared_examples_for 'requirements achieved' do |description|
    it do
      expect(achievement['requirements'].first).to include(
        'achieved' => true,
        'description' => description
      )
    end
  end

  shared_examples_for 'requirements not achieved' do |description|
    it do
      expect(achievement['requirements'].first).to include(
        'achieved' => false,
        'description' => description
      )
    end
  end

  shared_examples_for 'download available' do |type|
    it do
      expect(achievement['download']).to include(
        'available' => true,
        'description' => nil,
        'url' => "https://xikolo.de/certificate/render?course_id=#{course.id}&type=#{type}"
      )
    end
  end

  shared_examples_for 'download unreleased' do
    it do
      expect(achievement['download']).to include(
        'available' => false,
        'description' => 'Once the certificate is released, you can download it here.',
        'url' => nil
      )
    end
  end

  shared_examples_for 'download unavailable' do
    it { expect(achievement['download']).to be_nil }
  end

  shared_examples_for 'progress available' do
    it do
      expect(achievement['download']).to include(
        'type' => 'progress',
        'url' => "https://xikolo.de/courses/#{course.course_code}/progress"
      )
    end
  end

  describe 'Confirmation of Participation' do
    subject(:achievement) do
      json.find {|achievement| achievement['type'] == 'confirmation_of_participation' }
    end

    it { expect(achievement['name']).to eq('Confirmation of Participation') }

    context 'when the user is not enrolled' do
      it_behaves_like 'unachievable'
      it_behaves_like 'download unavailable'

      it 'returns correct completion information' do
        expect(achievement['description']).to eq('You did not yet complete enough learning units to achieve your confirmation for this course.')
        expect(achievement['visits']).to match hash_including('achieved' => 0, 'total' => 0, 'percentage' => 0)
      end
    end

    context 'when the user is enrolled' do
      before { create(:enrollment, course:, user_id:) }

      context 'and there is no CoP' do
        let(:course_params) { {cop_enabled: false} }

        it 'returns correct completion information' do
          expect(achievement['description']).to eq('A confirmation is not offered for this course.')
          expect(achievement['requirements']).to be_blank
          expect(achievement['visits']).to match hash_including('achieved' => 0, 'total' => 1, 'percentage' => 0)
        end

        it_behaves_like 'unachievable'
        it_behaves_like 'download unavailable'
      end

      context 'and the user has qualified for the CoP' do
        before { create(:visit, item:, user_id:) }

        context '(not released yet)' do
          let(:course_params) { super().merge(records_released: false) }

          it 'returns correct completion information' do
            expect(achievement['description']).to eq('Congratulations on achieving a confirmation for this course! Once the confirmation is released by the teaching team, you can download it here.')
            expect(achievement['visits']).to match hash_including('achieved' => 1, 'total' => 1, 'percentage' => 100)
          end

          it_behaves_like 'achieved'
          it_behaves_like 'requirements achieved', 'Complete at least 50% of the learning units.'
          it_behaves_like 'download unreleased'
        end

        context '(released)' do
          let(:course_params) { super().merge(records_released: true) }

          it 'returns correct completion information' do
            expect(achievement['description']).to eq('Congratulations! You achieved a confirmation for this course.')
            expect(achievement['visits']).to match hash_including('achieved' => 1, 'total' => 1, 'percentage' => 100)
          end

          it_behaves_like 'achieved'
          it_behaves_like 'requirements achieved', 'Complete at least 50% of the learning units.'
          it_behaves_like 'download available', 'ConfirmationOfParticipation'
        end
      end

      describe 'and requirements for CoP are not fulfilled' do
        it { expect(achievement['description']).to eq('You did not yet complete enough learning units to achieve your confirmation for this course.') }

        it_behaves_like 'achievable'
        it_behaves_like 'requirements not achieved', 'Complete at least 50% of the learning units.'
        it_behaves_like 'progress available'

        context 'with ended course' do
          let(:course_params) { super().merge(status: 'archive', start_date: 2.weeks.ago, end_date: 1.week.ago) }

          it 'returns correct completion information' do
            expect(achievement['description']).to eq('You did not yet complete enough learning units to achieve your confirmation for this course.')
            expect(achievement['visits']).to match hash_including('achieved' => 0, 'total' => 1, 'percentage' => 0)
          end

          it_behaves_like 'achievable'
          it_behaves_like 'requirements not achieved', 'Complete at least 50% of the learning units.'
          it_behaves_like 'progress available'
        end
      end
    end
  end

  describe 'Record of Achievement' do
    subject(:achievement) do
      json.find {|achievement| achievement['type'] == 'record_of_achievement' }
    end

    before { create(:enrollment, course:, user_id:) }

    it { expect(achievement['name']).to eq('Record of Achievement') }

    context 'and there is no RoA' do
      let(:course_params) { super().merge(roa_enabled: false) }

      it 'returns correct completion information' do
        expect(achievement['description']).to eq('A certificate is not offered for this course.')
        expect(achievement['requirements']).to be_blank
        expect(achievement['points']).to match hash_including('achieved' => 0, 'total' => 1.0, 'percentage' => 0)
      end

      it_behaves_like 'unachievable'
      it_behaves_like 'download unavailable'
    end

    context 'and the user has qualified for the RoA' do
      let(:dpoints) { 8 }

      before { create(:result, item:, user_id:, dpoints:) }

      context '(not yet released)' do
        let(:course_params) { super().merge(records_released: false) }

        it 'returns correct completion information' do
          expect(achievement['description']).to eq('Congratulations on achieving a certificate for this course! Once the certificate is released by the teaching team you can download it here.')
          expect(achievement['points']).to match hash_including('achieved' => 0.8, 'total' => 1.0, 'percentage' => 80)
        end

        it_behaves_like 'achieved'
        it_behaves_like 'requirements achieved', 'Achieve 50% of the overall score in graded assignments.'
        it_behaves_like 'download unreleased'

        context 'by reaching the exact threshold' do
          let(:dpoints) { 5 }

          it 'returns correct completion information' do
            expect(achievement['description']).to eq('Congratulations on achieving a certificate for this course! Once the certificate is released by the teaching team you can download it here.')
            expect(achievement['points']).to match hash_including('achieved' => 0.5, 'total' => 1.0, 'percentage' => 50)
          end

          it_behaves_like 'achieved'
          it_behaves_like 'requirements achieved', 'Achieve 50% of the overall score in graded assignments.'
          it_behaves_like 'download unreleased'
        end
      end

      context '(released)' do
        let(:course_params) { super().merge(records_released: true) }

        it 'returns correct completion information' do
          expect(achievement['description']).to eq('Congratulations! You achieved a certificate for this course by scoring high enough in the graded assignments.')
          expect(achievement['points']).to match hash_including('achieved' => 0.8, 'total' => 1.0, 'percentage' => 80)
        end

        it_behaves_like 'achieved'
        it_behaves_like 'requirements achieved', 'Achieve 50% of the overall score in graded assignments.'
        it_behaves_like 'download available', 'RecordOfAchievement'
      end
    end

    context 'and requirements for the RoA are not fulfilled' do
      it 'returns correct completion information' do
        expect(achievement['description']).to eq('You did not score enough points in graded exams, yet.')
        expect(achievement['points']).to match hash_including('achieved' => 0.0, 'total' => 1.0, 'percentage' => 0)
      end

      it_behaves_like 'achievable'
      it_behaves_like 'requirements not achieved', 'Achieve 50% of the overall score in graded assignments.'
      it_behaves_like 'progress available'

      context 'with some points achieved' do
        before { create(:result, item:, user_id:, dpoints: 2) }

        it 'returns correct completion information' do
          expect(achievement['description']).to eq('You did not score enough points in graded exams, yet.')
          expect(achievement['points']).to match hash_including('achieved' => 0.2, 'total' => 1.0, 'percentage' => 20)
        end

        it_behaves_like 'achievable'
        it_behaves_like 'requirements not achieved', 'Achieve 50% of the overall score in graded assignments.'
        it_behaves_like 'progress available'
      end

      context '(calculation precision)' do
        let!(:item) { create(:item, :homework, item_params.merge(max_dpoints: 500)) }

        before do
          create(:result, item:, user_id:, dpoints: 50)
          create(:item, :homework, item_params.merge(max_dpoints: 10))
          bonus_item = create(:item, :quiz, :bonus, item_params.merge(max_dpoints: 20))
          create(:result, item: bonus_item, user_id:, dpoints: 20)
        end

        it 'returns correct completion information with low precision' do
          expect(achievement['description']).to eq('You did not score enough points in graded exams, yet.')
          expect(achievement['points']).to match hash_including('achieved' => 7.0, 'total' => 51.0, 'percentage' => 13)
        end

        it_behaves_like 'achievable'
        it_behaves_like 'requirements not achieved', 'Achieve 50% of the overall score in graded assignments.'
        it_behaves_like 'progress available'
      end

      context 'after course end' do
        let(:course_params) { super().merge(status: 'archive', end_date: 1.week.ago) }

        it 'returns correct completion information' do
          expect(achievement['description']).to eq('This course has ended. Certificates were only available during the active course period.')
          expect(achievement['points']).to match hash_including('achieved' => 0.0, 'total' => 1.0, 'percentage' => 0)
        end

        it_behaves_like 'unachievable'
        it_behaves_like 'requirements not achieved', 'Achieve 50% of the overall score in graded assignments.'
        it_behaves_like 'download unavailable'

        context 'with course reactivation' do
          let(:course_params) { super().merge(on_demand: true) }

          it 'returns correct completion information' do
            expect(achievement['description']).to eq('This course has ended. If you still would like to achieve a certificate for this course, you can reactivate it now.')
            expect(achievement['points']).to match hash_including('achieved' => 0.0, 'total' => 1.0, 'percentage' => 0)
          end

          it_behaves_like 'achievable'
          it_behaves_like 'requirements not achieved', 'Achieve 50% of the overall score in graded assignments.'
          it_behaves_like 'progress available'
        end
      end

      context 'in course running forever' do
        let(:course_params) { super().merge(end_date: nil) }
        let(:item_params) { super().merge(submission_deadline: nil) }

        before { item }

        it 'returns correct completion information' do
          expect(achievement['description']).to eq('You did not score enough points in graded exams, yet.')
          expect(achievement['points']).to match hash_including('achieved' => 0.0, 'total' => 1.0, 'percentage' => 0)
        end

        it_behaves_like 'achievable'
        it_behaves_like 'requirements not achieved', 'Achieve 50% of the overall score in graded assignments.'
        it_behaves_like 'progress available'
      end
    end

    context 'when the user is not enrolled' do
      before { Enrollment.destroy_all }

      it 'returns correct completion information' do
        expect(achievement['description']).to eq('You did not score enough points in graded exams, yet.')
        expect(achievement['points']).to match hash_including('achieved' => 0.0, 'total' => 0.0, 'percentage' => 0)
      end

      it_behaves_like 'unachievable'
      it_behaves_like 'download unavailable'
    end
  end

  context 'when the request is sent with a different language' do
    let(:opts) { {headers: {'Accept-Language' => 'de'}} }

    it { expect(request.response.headers['CONTENT_LANGUAGE']).to eq('de') }

    it do
      cop = json.find {|achievement| achievement['type'] == 'confirmation_of_participation' }
      expect(cop['name']).to eq('Teilnahmebestätigung')
    end

    it do
      roa = json.find {|achievement| achievement['type'] == 'record_of_achievement' }
      expect(roa['name']).to eq('Leistungsnachweis')
    end
  end
end

# frozen_string_literal: true

require 'spec_helper'

describe StatisticsController, type: :controller do
  describe "GET 'show'" do
    subject { json }

    let(:json) { request.call; JSON.parse response.body }
    let(:default_params) { {format: 'json'} }
    let(:request) { -> { get :show, params: {course_id: students.first.course_id} } }

    let(:course) { create(:course, enrollment_delta: 0) }
    let(:students) { create_list(:enrollment, 5, course:) }

    before do
      # Create another course with five enrollments
      create_list(:enrollment, 5, course: create(:course))
    end

    describe 'response' do
      subject { request.call; response }

      its(:status) { is_expected.to eq 200 }
    end

    describe 'filter enrollments of last day' do
      before do
        # Create an old enrollment
        create(:enrollment, course:, created_at: 2.days.ago)
      end

      its(['enrollments']) { is_expected.to be 6 }
      its(['last_day_enrollments']) { is_expected.to be 5 }
    end

    describe 'filter enrollments of last 7 days' do
      before do
        # Create an old and another, even older enrollment
        create(:enrollment, course:, created_at: 2.days.ago)
        create(:enrollment, course:, created_at: 9.days.ago)
      end

      its(['enrollments']) { is_expected.to be 7 }
      its(['last_day_enrollments']) { is_expected.to be 5 }
      its(['last_7days_enrollments']) { is_expected.to be 6 }
    end

    describe 'with enrollment delta' do
      let(:course) { create(:course, enrollment_delta: 100) }

      its(['enrollments']) { is_expected.to be 105 }
      its(['last_day_enrollments']) { is_expected.to be 5 }
    end
  end

  describe "GET 'enrollment_stats'" do
    subject(:stats) { get :enrollment_stats, params: }

    let!(:course) { create(:course, classifiers: nil) }
    let(:category_cluster) { create(:cluster) }
    let!(:course_with_classifier_1) { create(:course, classifiers: {category_cluster.id => %w[internet]}) }
    let!(:course_with_classifier_2) { create(:course, classifiers: {category_cluster.id => %w[internet]}) }

    before do
      create_list(:enrollment, 5, course_id: course.id, created_at: 1.day.ago)
      enrollments_1 = create_list(:enrollment, 5, course_id: course_with_classifier_1.id, created_at: 1.day.ago)
      create_list(:enrollment, 5, course_id: course_with_classifier_2.id, created_at: 1.day.ago)
      create(:enrollment, user_id: enrollments_1.first.user_id, course_id: course_with_classifier_2.id, created_at: 1.day.ago)
      create(:enrollment, course_id: course_with_classifier_2.id, created_at: 3.days.ago)
    end

    context 'global stats' do
      let(:params) { {start_date: 2.days.ago.to_s, end_date: DateTime.now.to_s} }

      it 'responds successfully' do
        stats
        expect(response).to have_http_status :ok
      end

      describe 'json' do
        subject { stats; JSON.parse response.body }

        its(['total_enrollments']) { is_expected.to be 16 }
        its(['unique_enrolled_users']) { is_expected.to be 15 }
      end
    end

    context 'filter by classifier' do
      let(:params) { {start_date: 2.days.ago.to_s, end_date: DateTime.now.to_s, classifier_id: Classifier.find_by(title: 'internet').id} }

      it 'responds successfully' do
        stats
        expect(response).to have_http_status :ok
      end

      describe 'json' do
        subject { stats; JSON.parse response.body }

        its(['total_enrollments']) { is_expected.to be 11 }
        its(['unique_enrolled_users']) { is_expected.to be 10 }
      end
    end
  end
end

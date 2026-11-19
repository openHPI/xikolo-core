# frozen_string_literal: true

require 'spec_helper'

describe 'Enrollments: List', type: :request do
  subject(:list) { api.rel(:enrollments).get(params).value! }

  let(:api) { restify_with_headers(course_service.root_url).get.value }
  let(:params) { {user_id:} }

  let(:user_id) { create(:'account_service/user').id }
  let!(:enrollment) { create(:'course_service/enrollment', user_id:) }

  it { is_expected.to respond_with :ok }
  it { is_expected.to have(1).items }

  context 'with learning evaluation' do
    around {|example| perform_enqueued_jobs(&example) }

    let(:params) { super().merge(learning_evaluation: 'true') }

    before do
      CourseService::CourseProgress.find_by!(
        course: enrollment.course, user_id:
      ).update!(
        main_dpoints: 19_0,
        bonus_dpoints: 0,
        max_dpoints: 28_0,
        visits: 12,
        max_visits: 134,
        points_percentage_fpoints: 67_85,
        visits_percentage_fpoints: 8_95
      )
    end

    it { is_expected.to respond_with :ok }
    it { is_expected.to have(1).items }

    # That's a regression test. The decorator added rounding errors by using the Ruby std-lib.
    # We use BigDecimal instead for a more precise floating-point arithmetic.
    it 'applies the correct percentage rounding' do
      expect(list.map(&:to_hash)).to match([
        a_hash_including(
          'points' => {'maximal' => 28, 'achieved' => 19, 'percentage' => 67.85},
          'visits' => {'total' => 134, 'visited' => 12, 'percentage' => 8.95}
        ),
      ])
    end
  end
end

# frozen_string_literal: true

require 'spec_helper'

describe Course, '#prerequisites', type: :model do
  subject(:status) { course.prerequisites.status_for(user_id) }

  let(:course) { create(:'course_service/course') }
  let(:user_id) { generate(:user_id) }
  let(:other_course) { create(:'course_service/course', :archived, records_released: true, roa_enabled: true) }
  let(:other_enrollment) { create(:'course_service/enrollment', course: other_course, user_id:) }

  context 'by default' do
    it { is_expected.to be_fulfilled }
  end

  describe 'requiring a RoA in another course' do
    let!(:item) { create(:'course_service/item', :homework, :with_max_points, section: create(:'course_service/section', course: other_course)) }

    before do
      track = create(:'course_service/course_set')
      track.courses << course

      requirement = create(:'course_service/course_set')
      requirement.courses << other_course

      create(:'course_service/course_set_relation', source_set: track, target_set: requirement, kind: 'requires_roa')
    end

    context 'when the user did not enroll in the required course' do
      it { is_expected.not_to be_fulfilled }

      it 'allows reactivation of the course' do
        expect(status.sets.first.free_reactivation?).to be true
      end

      it 'has no score for the course' do
        expect(status.sets.first.score).to be_nil
      end
    end

    context 'when the user enrolled, but did not gain a RoA in the required course' do
      before { other_enrollment }

      it { is_expected.not_to be_fulfilled }

      it 'allows reactivation of the course' do
        expect(status.sets.first.free_reactivation?).to be true
      end

      it 'has no score for the course' do
        expect(status.sets.first.score).to be_nil
      end

      context 'when the course does not offer reactivations' do
        before { other_course.update!(on_demand: false) }

        it 'does not allow reactivation of the course' do
          expect(status.sets.first.free_reactivation?).to be false
        end
      end

      context 'when course has not ended yet' do
        let(:other_course) { create(:'course_service/course', :active, roa_enabled: true) }

        it 'does not allow reactivation of the course' do
          expect(status.sets.first.free_reactivation?).to be false
        end
      end

      context 'when the enrollment is currently reactivated' do
        before { other_enrollment.update!(forced_submission_date: 6.weeks.from_now) }

        it 'does not allow reactivation of the course' do
          expect(status.sets.first.free_reactivation?).to be false
        end
      end

      context 'when the enrollment has been reactivated before' do
        before { other_enrollment.update!(forced_submission_date: 2.years.from_now) }

        it 'does not allow reactivation of the course' do
          expect(status.sets.first.free_reactivation?).to be false
        end
      end
    end

    context 'when the user enrolled and gained a RoA in the required course' do
      let!(:other_enrollment) { create(:'course_service/enrollment', course: other_course, user_id:) }

      before { create(:'course_service/result', item:, user_id:, dpoints: 8) }

      it { is_expected.to be_fulfilled }

      it 'does not allow reactivation of the course' do
        expect(status.sets.first.free_reactivation?).to be false
      end

      it 'has the correct score for the course' do
        expect(status.sets.first.score.to_s).to eq '80.0'
      end

      context 'when the user un-enrolled' do
        before { other_enrollment.archive! }

        it { is_expected.to be_fulfilled }

        it 'does not allow reactivation of the course' do
          expect(status.sets.first.free_reactivation?).to be false
        end
      end
    end
  end

  describe 'requiring a CoP in another course' do
    let(:other_course) { create(:'course_service/course', :archived, records_released: true, cop_enabled: true) }
    let!(:item) { create(:'course_service/item', section: create(:'course_service/section', course: other_course)) }

    before do
      track = create(:'course_service/course_set')
      track.courses << course

      requirement = create(:'course_service/course_set')
      requirement.courses << other_course

      create(:'course_service/course_set_relation', source_set: track, target_set: requirement, kind: 'requires_cop')
    end

    context 'when the user did not enroll in the required course' do
      it { is_expected.not_to be_fulfilled }

      it 'does not allow reactivation of the course' do
        expect(status.sets.first.free_reactivation?).to be false
      end

      it 'has false as score for the course' do
        expect(status.sets.first.score).to be false
      end
    end

    context 'when the user enrolled, but did not gain a CoP in the required course' do
      before do
        create(:'course_service/enrollment', course: other_course, user_id:)
      end

      it { is_expected.not_to be_fulfilled }

      it 'does not allow reactivation of the course' do
        expect(status.sets.first.free_reactivation?).to be false
      end

      it 'has false as score for the course' do
        expect(status.sets.first.score).to be false
      end
    end

    context 'when the user enrolled and gained a CoP in the required course' do
      before do
        create(:'course_service/enrollment', course: other_course, user_id:)
        create(:'course_service/visit', item:, user_id:)
      end

      it { is_expected.to be_fulfilled }

      it 'does not allow reactivation of the course' do
        expect(status.sets.first.free_reactivation?).to be false
      end

      it 'has true as score for the course' do
        expect(status.sets.first.score).to be true
      end
    end
  end

  describe 'requiring a RoA in one of multiple courses (iterations)' do
    let(:older_course) { create(:'course_service/course', :archived, start_date: 5.years.ago, records_released: true, roa_enabled: true) }
    let(:newer_course) { create(:'course_service/course', :archived, start_date: 2.years.ago, records_released: true, roa_enabled: true) }
    let!(:older_item) { create(:'course_service/item', :homework, :with_max_points, section: create(:'course_service/section', course: older_course)) }
    let!(:newer_item) { create(:'course_service/item', :homework, :with_max_points, section: create(:'course_service/section', course: newer_course)) }

    before do
      track = create(:'course_service/course_set')
      track.courses << course

      requirement = create(:'course_service/course_set')
      requirement.courses << older_course << newer_course

      create(:'course_service/course_set_relation', source_set: track, target_set: requirement, kind: 'requires_roa')
    end

    context 'when the user did not enroll in either course' do
      it { is_expected.not_to be_fulfilled }

      it 'selects the newer course as representative' do
        expect(status.sets.first.representative).to eq newer_course
      end

      it 'allows reactivation of the newer course' do
        expect(status.sets.first.free_reactivation?).to be true
      end
    end

    context 'when the user enrolled, but did not gain a RoA in the older course' do
      before { create(:'course_service/enrollment', course: older_course, user_id:) }

      it { is_expected.not_to be_fulfilled }

      it 'selects the newer course as representative' do
        expect(status.sets.first.representative).to eq newer_course
      end

      it 'allows reactivation of the newer course' do
        expect(status.sets.first.free_reactivation?).to be true
      end
    end

    context 'when the user enrolled and gained a RoA in the older course' do
      before do
        create(:'course_service/enrollment', course: older_course, user_id:)
        create(:'course_service/result', item: older_item, user_id:, dpoints: 8)
      end

      it { is_expected.to be_fulfilled }

      it 'selects the older course as representative' do
        expect(status.sets.first.representative).to eq older_course
      end

      it 'does not allow reactivation of either course' do
        expect(status.sets.first.free_reactivation?).to be false
      end
    end

    context 'when the user enrolled and gained a RoA in the newer course' do
      before do
        create(:'course_service/enrollment', course: newer_course, user_id:)
        create(:'course_service/result', item: newer_item, user_id:, dpoints: 8)
      end

      it { is_expected.to be_fulfilled }

      it 'selects the newer course as representative' do
        expect(status.sets.first.representative).to eq newer_course
      end

      it 'does not allow reactivation of either course' do
        expect(status.sets.first.free_reactivation?).to be false
      end
    end

    context 'when the user enrolled in both courses and completed neither' do
      before do
        create(:'course_service/enrollment', course: older_course, user_id:)
        create(:'course_service/enrollment', course: newer_course, user_id:)
      end

      it { is_expected.not_to be_fulfilled }

      it 'selects the newer course as representative' do
        expect(status.sets.first.representative).to eq newer_course
      end

      it 'allows reactivation of the newer course' do
        expect(status.sets.first.free_reactivation?).to be true
      end
    end

    context 'when the user enrolled and gained a RoA in both courses' do
      before do
        create(:'course_service/enrollment', course: older_course, user_id:)
        create(:'course_service/result', item: older_item, user_id:, dpoints: 8)
        create(:'course_service/enrollment', course: newer_course, user_id:)
        create(:'course_service/result', item: newer_item, user_id:, dpoints: 8)
      end

      it { is_expected.to be_fulfilled }

      it 'selects the newer course as representative' do
        expect(status.sets.first.representative).to eq newer_course
      end

      it 'does not allow reactivation of either course' do
        expect(status.sets.first.free_reactivation?).to be false
      end
    end
  end

  describe 'requiring a CoP in one of multiple courses (iterations)' do
    let(:older_course) { create(:'course_service/course', :archived, start_date: 5.years.ago, records_released: true, cop_enabled: true) }
    let(:newer_course) { create(:'course_service/course', :archived, start_date: 2.years.ago, records_released: true, cop_enabled: true) }
    let!(:older_item) { create(:'course_service/item', section: create(:'course_service/section', course: older_course)) }
    let!(:newer_item) { create(:'course_service/item', section: create(:'course_service/section', course: newer_course)) }

    before do
      track = create(:'course_service/course_set')
      track.courses << course

      requirement = create(:'course_service/course_set')
      requirement.courses << older_course << newer_course

      create(:'course_service/course_set_relation', source_set: track, target_set: requirement, kind: 'requires_cop')
    end

    context 'when the user did not enroll in either course' do
      it { is_expected.not_to be_fulfilled }

      it 'selects the newer course as representative' do
        expect(status.sets.first.representative).to eq newer_course
      end
    end

    context 'when the user enrolled, but did not gain a CoP in the older course' do
      before { create(:'course_service/enrollment', course: older_course, user_id:) }

      it { is_expected.not_to be_fulfilled }

      it 'selects the newer course as representative' do
        expect(status.sets.first.representative).to eq newer_course
      end
    end

    context 'when the user enrolled and gained a CoP in the older course' do
      before do
        create(:'course_service/enrollment', course: older_course, user_id:)
        create(:'course_service/visit', item: older_item, user_id:)
      end

      it { is_expected.to be_fulfilled }

      it 'selects the older course as representative' do
        expect(status.sets.first.representative).to eq older_course
      end
    end

    context 'when the user enrolled and gained a CoP in the newer course' do
      before do
        create(:'course_service/enrollment', course: newer_course, user_id:)
        create(:'course_service/visit', item: newer_item, user_id:)
      end

      it { is_expected.to be_fulfilled }

      it 'selects the newer course as representative' do
        expect(status.sets.first.representative).to eq newer_course
      end
    end

    context 'when the user enrolled in both courses and completed neither' do
      before do
        create(:'course_service/enrollment', course: older_course, user_id:)
        create(:'course_service/enrollment', course: newer_course, user_id:)
      end

      it { is_expected.not_to be_fulfilled }

      it 'selects the newer course as representative' do
        expect(status.sets.first.representative).to eq newer_course
      end
    end

    context 'when the user enrolled and gained a RoA in both courses' do
      before do
        create(:'course_service/enrollment', course: older_course, user_id:)
        create(:'course_service/visit', item: older_item, user_id:)
        create(:'course_service/enrollment', course: newer_course, user_id:)
        create(:'course_service/visit', item: newer_item, user_id:)
      end

      it { is_expected.to be_fulfilled }

      it 'selects the newer course as representative' do
        expect(status.sets.first.representative).to eq newer_course
      end
    end
  end

  describe 'multiple prerequisites' do
    let(:roa_course_1) { create(:'course_service/course', :archived, records_released: true, roa_enabled: true) }
    let(:roa_course_2) { create(:'course_service/course', :archived, records_released: true, roa_enabled: true) }
    let(:cop_course_1) { create(:'course_service/course', :archived, records_released: true, cop_enabled: true) }
    let(:cop_course_2) { create(:'course_service/course', :archived, records_released: true, cop_enabled: true) }

    before do
      track = create(:'course_service/course_set')
      track.courses << course

      roa_requirement_1 = create(:'course_service/course_set')
      roa_requirement_1.courses << roa_course_1

      create(:'course_service/course_set_relation', source_set: track, target_set: roa_requirement_1, kind: 'requires_roa')

      roa_requirement_2 = create(:'course_service/course_set')
      roa_requirement_2.courses << roa_course_2

      create(:'course_service/course_set_relation', source_set: track, target_set: roa_requirement_2, kind: 'requires_roa')

      cop_requirement_1 = create(:'course_service/course_set')
      cop_requirement_1.courses << cop_course_1

      create(:'course_service/course_set_relation', source_set: track, target_set: cop_requirement_1, kind: 'requires_cop')

      cop_requirement_2 = create(:'course_service/course_set')
      cop_requirement_2.courses << cop_course_2

      create(:'course_service/course_set_relation', source_set: track, target_set: cop_requirement_2, kind: 'requires_cop')
    end

    context 'when none of the requirements are fulfilled' do
      it { is_expected.not_to be_fulfilled }
    end

    context 'when only some requirements are fulfilled' do
      before do
        # Got the two RoAs, but no enrollment for the other courses
        roa_item_1 = create(:'course_service/item', :homework, :with_max_points, section: create(:'course_service/section', course: roa_course_1))
        create(:'course_service/enrollment', course: roa_course_1, user_id:)
        create(:'course_service/result', item: roa_item_1, user_id:, dpoints: 8)

        roa_item_2 = create(:'course_service/item', :homework, :with_max_points, section: create(:'course_service/section', course: roa_course_2))
        create(:'course_service/enrollment', course: roa_course_2, user_id:)
        create(:'course_service/result', item: roa_item_2, user_id:, dpoints: 8)
      end

      it { is_expected.not_to be_fulfilled }
    end

    context 'when all requirements are fulfilled' do
      before do
        roa_item_1 = create(:'course_service/item', :homework, :with_max_points, section: create(:'course_service/section', course: roa_course_1))
        create(:'course_service/enrollment', course: roa_course_1, user_id:)
        create(:'course_service/result', item: roa_item_1, user_id:, dpoints: 8)

        roa_item_2 = create(:'course_service/item', :homework, :with_max_points, section: create(:'course_service/section', course: roa_course_2))
        create(:'course_service/enrollment', course: roa_course_2, user_id:)
        create(:'course_service/result', item: roa_item_2, user_id:, dpoints: 8)

        cop_item_1 = create(:'course_service/item', section: create(:'course_service/section', course: cop_course_1))
        create(:'course_service/enrollment', course: cop_course_1, user_id:)
        create(:'course_service/visit', item: cop_item_1, user_id:)

        cop_item_2 = create(:'course_service/item', section: create(:'course_service/section', course: cop_course_2))
        create(:'course_service/enrollment', course: cop_course_2, user_id:)
        create(:'course_service/visit', item: cop_item_2, user_id:)
      end

      it { is_expected.to be_fulfilled }
    end
  end
end

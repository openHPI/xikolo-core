# frozen_string_literal: true

require 'spec_helper'

describe CourseService::ProgressesController, type: :controller do
  subject { action; response }

  include_context 'course_service API controller'

  let(:json) { JSON.parse response.body }
  let(:default_params) { {format: 'json'} }

  let(:action) { get :index, params: {course_id: course.id, user_id:} }

  let!(:course) { create(:'course_service/course') }
  let(:user_id) { create(:'account_service/user').id }
  let(:other_user_id) { create(:'account_service/user').id }

  let(:section1_params) { {id: '00000002-3100-4444-9999-000000000001'} }
  let(:section1) { create(:'course_service/section', {course:, position: 1, start_date: 10.days.ago.iso8601}.merge(section1_params)) }
  let(:item11_params) { {} }
  let(:item11) { create(:'course_service/item', {section: section1, position: 1}.merge(item11_params)) }
  let(:item12_params) { {} }
  let(:item12) { create(:'course_service/item', {section: section1, position: 2}.merge(item12_params)) }
  let(:item13_params) { {} }
  let(:item13) { create(:'course_service/item', {section: section1, position: 3}.merge(item13_params)) }
  let(:item14_params) { {} }
  let(:item14) { create(:'course_service/item', {section: section1, position: 4}.merge(item14_params)) }
  let(:item15_params) { {optional: true} }
  let(:item15) { create(:'course_service/item', {section: section1, position: 10}.merge(item15_params)) }

  let(:section2_params) { {id: '00000002-3100-4444-9999-000000000002'} }
  let(:section2) { create(:'course_service/section', {course:, position: 2, start_date: 10.days.ago.iso8601}.merge(section2_params)) }
  let(:item21_params) { {} }
  let(:item21) { create(:'course_service/item', {section: section2, position: 1}.merge(item21_params)) }
  let(:item22_params) { {submission_deadline: 5.days.from_now} }
  let(:item22) { create(:'course_service/item', {section: section2, position: 2}.merge(item22_params)) }

  let(:section3_params) { {id: '00000002-3100-4444-9999-000000000003'} }
  let(:section3) { create(:'course_service/section', {course:, position: 3, start_date: 10.days.ago.iso8601}.merge(section3_params)) }
  let(:item31_params) { {} }
  let(:item31) { create(:'course_service/item', {section: section3, position: 1}.merge(item31_params)) }
  let(:item32_params) { {} }
  let(:item32) { create(:'course_service/item', {section: section3, position: 2}.merge(item32_params)) }

  shared_examples 'a course progress' do
    it 'is declared as course block' do
      expect(subject['kind']).to eq 'course'
    end

    it 'does not include section specific fields' do
      expect(subject.keys).not_to include 'title'
      expect(subject.keys).not_to include 'items'
    end
  end

  shared_examples 'a section progress' do |section|
    it 'contains section properties' do
      expect(subject['kind']).to eq 'section'
      expect(subject['title']).to eq send(section).title
      expect(subject['resource_id']).to eq send(section).id
      expect(subject['alternative_state']).to eq send(section).alternative_state.presence_in(%w[parent child])
    end
  end

  shared_examples 'the section1 progress' do |section1|
    it_behaves_like 'a section progress', section1

    context 'items' do
      subject { super()['items'] }

      its(:size) { is_expected.to eq 5 }

      context 'item 1' do
        it_behaves_like 'a item', 0, :item11, user_state: 'new'
      end

      context 'item 2' do
        it_behaves_like 'a item', 1, :item12, user_state: 'graded', user_points: 5.5
      end

      context 'item 3' do
        it_behaves_like 'a item', 2, :item13, user_state: 'graded', user_points: 8.0
      end

      context 'item 4' do
        it_behaves_like 'a item', 3, :item14, user_state: 'new'
      end

      context 'item 5' do
        it_behaves_like 'a item', 4, :item15, user_state: 'new'
      end
    end
  end

  shared_examples 'the section2 progress' do |section2|
    it_behaves_like 'a section progress', section2

    context 'items' do
      subject { super()['items'] }

      its(:size) { is_expected.to eq 2 }

      context 'item 1' do
        it_behaves_like 'a item', 0, :item21, user_state: 'visited'
      end

      context 'item 2' do
        it_behaves_like 'a item', 1, :item22, user_state: 'graded', user_points: 10.0
      end
    end
  end

  shared_examples 'the section3 progress' do |section3|
    it_behaves_like 'a section progress', section3

    context 'items' do
      subject { super()['items'] }

      its(:size) { is_expected.to eq 2 }

      context 'item 1' do
        it_behaves_like 'a item', 0, :item31, user_state: 'graded', user_points: 2.0
      end

      context 'item 2' do
        it_behaves_like 'a item', 1, :item32, user_state: 'new'
      end
    end
  end

  shared_examples 'the parent_section progress' do |parent_section|
    it_behaves_like 'a section progress', parent_section

    context 'items' do
      subject { super()['items'] }

      its(:size) { is_expected.to be_zero }
    end
  end

  shared_examples 'a item' do |position, item_name, opts|
    subject { super()[position] }

    let(:item) { send item_name }

    it 'exports needed item fields' do
      expect(subject).to include(
        'id',
        'title',
        'exercise_type',
        'content_type',
        'user_state',
        'optional',
        'max_points',
        'user_points'
      )
      expect(subject['id']).to eq item.id
      expect(subject['title']).to eq item.title
      expect(subject['exercise_type']).to eq item.exercise_type
      expect(subject['content_type']).to eq item.content_type
      expect(subject['user_state']).to eq opts[:user_state]
      expect(subject['optional']).to eq item.optional?
      expect(subject['max_points']).to eq item.max_dpoints&.fdiv 10
      expect(subject['user_points']).to eq opts[:user_points]
    end
  end

  describe '#index' do
    context 'empty course' do
      its(:status) { is_expected.to eq 200 }

      context 'json' do
        subject { action; json }

        its(:size) { is_expected.to eq 1 }

        context 'course progress' do
          subject { super()[0] }

          its(:keys) { is_expected.to match_array %w[kind resource_id] }
          its(['kind']) { is_expected.to eq 'course' }
        end
      end
    end

    ##############################
    context 'with item visits' do
      ##############################
      before do
        item11; item12; item13; item14; item15
        create(:'course_service/visit', item: item11, user_id: other_user_id)
        create(:'course_service/visit', item: item12, user_id:)
        create(:'course_service/visit', item: item15, user_id:)
        create(:'course_service/visit', item: item21, user_id:)
        item21; item22
      end

      its(:status) { is_expected.to eq 200 }

      context 'json' do
        subject { action; json }

        its(:size) { is_expected.to eq 3 }

        context 'section 1 progress' do
          subject { super()[0] }

          it_behaves_like 'a section progress', :section1

          context 'items' do
            subject { super()['items'] }

            its(:size) { is_expected.to eq 5 }

            context 'item 1' do
              it_behaves_like 'a item', 0, :item11, user_state: 'new'
            end

            context 'item 2' do
              it_behaves_like 'a item', 1, :item12, user_state: 'visited'
            end

            context 'item 3' do
              it_behaves_like 'a item', 2, :item13, user_state: 'new'
            end

            context 'item 4' do
              it_behaves_like 'a item', 3, :item14, user_state: 'new'
            end

            context 'item 5' do
              it_behaves_like 'a item', 4, :item15, user_state: 'visited'
            end
          end
        end

        context 'section 2 progress' do
          subject { super()[1] }

          it_behaves_like 'a section progress', :section2

          context 'items' do
            subject { super()['items'] }

            its(:size) { is_expected.to eq 2 }

            context 'item 1' do
              it_behaves_like 'a item', 0, :item21, user_state: 'visited'
            end

            context 'item 2' do
              it_behaves_like 'a item', 1, :item22, user_state: 'new'
            end
          end
        end

        context 'course progress' do
          subject { super()[2] }

          it_behaves_like 'a course progress'
        end
      end
    end

    ####################################
    context 'with submitted results' do
      ####################################
      let(:item12_params) { {content_type: 'quiz', exercise_type: 'selftest', max_dpoints: 70} }
      let(:item13_params) { {content_type: 'lti', exercise_type: 'selftest', max_dpoints: 30} }
      let(:item14_params) { {content_type: 'quiz', exercise_type: 'selftest', max_dpoints: 80} }
      let(:item21_params) { {content_type: 'quiz', exercise_type: 'main', max_dpoints: 10} }
      let(:item22_params) { {content_type: 'quiz', exercise_type: 'selftest', max_dpoints: 120} }

      before do
        item14; item13; item12; item11; item15
        create(:'course_service/visit', item: item14, user_id: other_user_id)
        create(:'course_service/result', item: item14, user_id: other_user_id, dpoints: 30)
        create(:'course_service/visit', item: item13, user_id:)
        create(:'course_service/result', item: item13, user_id:, dpoints: 80)
        create(:'course_service/visit', item: item12, user_id:)
        create(:'course_service/result', item: item12, user_id:, dpoints: 55)
        item21; item22
        create(:'course_service/visit', item: item21, user_id:)
        create(:'course_service/visit', item: item22, user_id:)
        create(:'course_service/result', item: item22, user_id:, dpoints: 50)
        create(:'course_service/result', item: item22, user_id:, dpoints: 100)
      end

      its(:status) { is_expected.to eq 200 }

      context 'json' do
        subject { action; json }

        its(:size) { is_expected.to eq 3 }

        context 'section 1 progress' do
          subject { super()[0] }

          it_behaves_like 'the section1 progress', :section1
        end

        context 'section 2 progress' do
          subject { super()[1] }

          it_behaves_like 'the section2 progress', :section2
        end

        context 'course progress' do
          subject { super()[2] }

          it_behaves_like 'a course progress'
        end

        context 'with alternative sections' do
          let!(:section_params) { {course:, start_date: 10.days.ago.iso8601} }
          let!(:parent_section) { create(:'course_service/section', {id: '00000002-3100-4444-9999-000000000004', alternative_state: 'parent', position: 1}.merge(section_params)) }
          let!(:section_child_params) { {alternative_state: 'child', parent_id: parent_section.id}.merge(section_params) }
          let!(:section1) { create(:'course_service/section', section_child_params.merge(position: 2, id: '00000002-3100-4444-9999-000000000001')) }
          let!(:section2) { create(:'course_service/section', section_child_params.merge(position: 8, id: '00000002-3100-4444-9999-000000000002')) }
          let(:section3_params) { super().merge(position: 3) }
          let(:item31_params) { {content_type: 'quiz', exercise_type: 'selftest', max_dpoints: 80} }

          before do
            item31; item32
            create(:'course_service/visit', item: item31, user_id:)
            create(:'course_service/result', item: item31, user_id:, dpoints: 20)
          end

          context 'with no section choice' do
            its(:size) { is_expected.to eq 3 }

            context 'parent section progress' do
              subject { super()[0] }

              it_behaves_like 'the parent_section progress', :parent_section
              its(['alternative_state']) { is_expected.to eq 'parent' }
              its(['discarded']) { is_expected.to be false }
            end

            context 'section 3 progress' do
              subject { super()[1] }

              it_behaves_like 'the section3 progress', :section3
              its(['alternative_state']) { is_expected.to be_nil }
              its(['discarded']) { is_expected.to be false }
            end

            context 'course progress' do
              subject { super()[2] }

              it_behaves_like 'a course progress'
            end
          end

          context 'with one section choice' do
            before do
              create(:'course_service/section_choice',
                section_id: parent_section.id, user_id:, choice_ids: [section1.id])
            end

            its(:size) { is_expected.to eq 4 }

            context 'parent section progress' do
              subject { super()[0] }

              it_behaves_like 'the parent_section progress', :parent_section
              its(['alternative_state']) { is_expected.to eq 'parent' }
              its(['discarded']) { is_expected.to be false }
            end

            context 'section 1 progress' do
              subject { super()[1] }

              it_behaves_like 'the section1 progress', :section1
              its(['alternative_state']) { is_expected.to eq 'child' }
              its(['discarded']) { is_expected.to be false }
            end

            context 'section 3 progress' do
              subject { super()[2] }

              its(['alternative_state']) { is_expected.to be_nil }
              its(['discarded']) { is_expected.to be false }
            end

            context 'course progress' do
              subject { super()[3] }

              it_behaves_like 'a course progress'
            end
          end

          context 'with two section choices' do
            before do
              create(:'course_service/section_choice',
                section_id: parent_section.id, user_id:, choice_ids: [section1.id, section2.id])
            end

            its(:size) { is_expected.to eq 5 }

            context 'parent section progress' do
              subject { super()[0] }

              it_behaves_like 'the parent_section progress', :parent_section
              its(['alternative_state']) { is_expected.to eq 'parent' }
              its(['discarded']) { is_expected.to be false }
            end

            context 'section 1 progress' do
              subject { super()[1] }

              it_behaves_like 'the section1 progress', :section1
              its(['alternative_state']) { is_expected.to eq 'child' }
              its(['discarded']) { is_expected.to be false }
            end

            context 'section 2 progress' do
              subject { super()[2] }

              it_behaves_like 'the section2 progress', :section2
              its(['alternative_state']) { is_expected.to eq 'child' }
              its(['discarded']) { is_expected.to be true }
            end

            context 'section 3 progress' do
              subject { super()[3] }

              it_behaves_like 'the section3 progress', :section3
              its(['alternative_state']) { is_expected.to be_nil }
              its(['discarded']) { is_expected.to be false }
            end

            context 'course progress' do
              subject { super()[4] }

              let(:learning_evaluation) do
                create(:'course_service/enrollment',
                  user_id:,
                  course_id: course.id)

                CourseService::Enrollment.with_learning_evaluation(
                  course.enrollments.where(user_id:)
                ).take!
              end

              it_behaves_like 'a course progress'

              it 'learning evaluation should arrive at the same results' do
                create(:'course_service/enrollment',
                  user_id:,
                  course_id: course.id)

                e = CourseService::Enrollment.with_learning_evaluation(
                  course.enrollments.where(user_id:)
                ).take!

                expect(e).to have_attributes(
                  visits_total: 6,
                  visits_visited: 3,
                  visits_percentage: 50
                )
              end
            end
          end
        end
      end
    end

    ###################################
    context 'with results not published yet' do
      ###################################
      let(:passed_datetime) { DateTime.now - 1.day }
      let(:next_datetime) { 1.day.from_now }
      let(:last_datetime) { DateTime.now + 2.days }
      let(:item12_params) do
        {content_type: 'quiz', exercise_type: 'main',
                             max_dpoints: 70, submission_publishing_date: passed_datetime}
      end
      let(:item13_params) do
        {content_type: 'lti', exercise_type: 'main',
                             max_dpoints: 30, submission_publishing_date: next_datetime}
      end
      let(:item14_params) do
        {content_type: 'quiz', exercise_type: 'main',
                             max_dpoints: 80, submission_publishing_date: last_datetime}
      end
      let(:item22_params) do
        {content_type: 'quiz', exercise_type: 'main',
                             max_dpoints: 120, submission_publishing_date: next_datetime}
      end

      before do
        item11; item12; item13; item14; item15
        create(:'course_service/visit', item: item14, user_id: other_user_id)
        create(:'course_service/result', item: item14, user_id: other_user_id, dpoints: 30)
        create(:'course_service/visit', item: item12, user_id:)
        create(:'course_service/result', item: item12, user_id:, dpoints: 50)
        create(:'course_service/visit', item: item13, user_id:)
        create(:'course_service/result', item: item13, user_id:, dpoints: 82)
        create(:'course_service/visit', item: item14, user_id:)
        create(:'course_service/result', item: item14, user_id:, dpoints: 20)
        item21; item22
        create(:'course_service/visit', item: item21, user_id:)
        create(:'course_service/visit', item: item22, user_id:)
      end

      its(:status) { is_expected.to eq 200 }

      context 'json' do
        subject { action; json }

        its(:size) { is_expected.to eq 3 }

        context 'section 1 progress' do
          subject { super()[0] }

          it_behaves_like 'a section progress', :section1

          context 'items' do
            subject { super()['items'] }

            its(:size) { is_expected.to eq 5 }

            context 'item 1' do
              it_behaves_like 'a item', 0, :item11, user_state: 'new'
            end

            context 'item 2' do
              it_behaves_like 'a item', 1, :item12, user_state: 'graded', user_points: 5.0
            end

            context 'item 3' do
              it_behaves_like 'a item', 2, :item13, user_state: 'submitted', user_points: 8.2
            end

            context 'item 4' do
              it_behaves_like 'a item', 3, :item14, user_state: 'submitted', user_points: 2.0
            end
          end
        end

        context 'section 2 progress' do
          subject { super()[1] }

          it_behaves_like 'a section progress', :section2

          context 'items' do
            subject { super()['items'] }

            its(:size) { is_expected.to eq 2 }

            context 'item 1' do
              it_behaves_like 'a item', 0, :item21, user_state: 'visited'
            end

            context 'item 2' do
              it_behaves_like 'a item', 1, :item22, user_state: 'visited'
            end
          end
        end

        context 'course progress' do
          subject { super()[2] }

          it_behaves_like 'a course progress'
        end
      end
    end

    context 'with unavailable resources' do
      let(:passed_datetime) { DateTime.now - 1.day }
      let(:next_datetime) { 1.day.from_now }
      let(:last_datetime) { DateTime.now + 2.days }
      let(:other_datetime) { DateTime.now + 1.hour }
      let(:item12_params) do
        {content_type: 'quiz', exercise_type: 'main',
                             max_dpoints: 70, submission_publishing_date: passed_datetime}
      end
      let(:item13_params) do
        {content_type: 'lti', exercise_type: 'main',
                             max_dpoints: 30, submission_publishing_date: next_datetime}
      end
      let(:item14_params) do
        {content_type: 'quiz', exercise_type: 'main',
                             max_dpoints: 80, submission_publishing_date: last_datetime}
      end
      let(:item22_params) do
        {content_type: 'quiz', exercise_type: 'main',
                             max_dpoints: 120, submission_publishing_date: next_datetime}
      end
      let(:section3_params) { {start_date: DateTime.now + 1.day} }
      let(:item32_params) do
        {content_type: 'quiz', exercise_type: 'main',
                             max_dpoints: 200, submission_publishing_date: other_datetime}
      end

      before do
        item11; item12; item13; item14; item15
        create(:'course_service/visit', item: item14, user_id: other_user_id)
        create(:'course_service/result', item: item14, user_id: other_user_id, dpoints: 3)
        create(:'course_service/visit', item: item12, user_id:)
        create(:'course_service/result', item: item12, user_id:, dpoints: 50)
        create(:'course_service/visit', item: item13, user_id:)
        create(:'course_service/result', item: item13, user_id:, dpoints: 82)
        create(:'course_service/visit', item: item14, user_id:)
        create(:'course_service/result', item: item14, user_id:, dpoints: 20)
        item21; item22
        create(:'course_service/visit', item: item21, user_id:)
        create(:'course_service/visit', item: item22, user_id:)
        item31; item32
        create(:'course_service/visit', item: item31, user_id:)
        create(:'course_service/visit', item: item32, user_id:)
        create(:'course_service/result', item: item32, user_id:, dpoints: 100)
      end

      its(:status) { is_expected.to eq 200 }

      it 'adds some not available items in section 1 or 2' do
        skip 'todo'
      end

      context 'json' do
        subject { action; json }

        its(:size) { is_expected.to eq 4 }

        context 'section 1 progress' do
          subject { super()[0] }

          it_behaves_like 'a section progress', :section1
          its(['available']) { is_expected.to be_truthy }

          context 'items' do
            subject { super()['items'] }

            its(:size) { is_expected.to eq 5 }

            context 'item 1' do
              it_behaves_like 'a item', 0, :item11, user_state: 'new'
            end

            context 'item 2' do
              it_behaves_like 'a item', 1, :item12, user_state: 'graded', user_points: 5.0
            end

            context 'item 3' do
              it_behaves_like 'a item', 2, :item13, user_state: 'submitted', user_points: 8.2
            end

            context 'item 4' do
              it_behaves_like 'a item', 3, :item14, user_state: 'submitted', user_points: 2.0
            end
          end
        end

        context 'section 2 progress' do
          subject { super()[1] }

          it_behaves_like 'a section progress', :section2
          its(['available']) { is_expected.to be_truthy }

          context 'items' do
            subject { super()['items'] }

            its(:size) { is_expected.to eq 2 }

            context 'item 1' do
              it_behaves_like 'a item', 0, :item21, user_state: 'visited'
            end

            context 'item 2' do
              it_behaves_like 'a item', 1, :item22, user_state: 'visited'
            end
          end
        end

        context 'section 3 progress' do
          subject { super()[2] }

          it_behaves_like 'a section progress', :section3
          its(['available']) { is_expected.to be_falsey }
          its(:keys) { is_expected.to match_array %w[kind title available resource_id alternative_state discarded] }
        end

        context 'course progress' do
          subject { super()[3] }

          it_behaves_like 'a course progress'
        end
      end
    end

    context 'with not published resources' do
      let(:passed_datetime) { DateTime.now - 1.day }
      let(:next_datetime) { 1.day.from_now }
      let(:last_datetime) { DateTime.now + 2.days }
      let(:other_datetime) { DateTime.now + 1.hour }
      let(:item12_params) do
        {content_type: 'quiz', exercise_type: 'main',
                             max_dpoints: 70, submission_publishing_date: passed_datetime}
      end
      let(:item13_params) do
        {content_type: 'lti', exercise_type: 'main',
                             max_dpoints: 30, submission_publishing_date: next_datetime}
      end
      let(:item14_params) do
        {content_type: 'quiz', exercise_type: 'main',
                             max_dpoints: 80, submission_publishing_date: last_datetime}
      end
      let(:item22_params) do
        {content_type: 'quiz', exercise_type: 'main',
                             max_dpoints: 120, submission_publishing_date: next_datetime}
      end
      let(:section3_params) { {published: false} }
      let(:item32_params) do
        {content_type: 'quiz', exercise_type: 'main',
                             max_dpoints: 200, submission_publishing_date: other_datetime}
      end

      before do
        item11; item12; item13; item14; item15
        create(:'course_service/visit', item: item14, user_id: other_user_id)
        create(:'course_service/result', item: item14, user_id: other_user_id, dpoints: 3)
        create(:'course_service/visit', item: item12, user_id:)
        create(:'course_service/result', item: item12, user_id:, dpoints: 50)
        create(:'course_service/visit', item: item13, user_id:)
        create(:'course_service/result', item: item13, user_id:, dpoints: 82)
        create(:'course_service/visit', item: item14, user_id:)
        create(:'course_service/result', item: item14, user_id:, dpoints: 20)
        item21; item22
        create(:'course_service/visit', item: item21, user_id:)
        create(:'course_service/visit', item: item22, user_id:)
        item31; item32
        create(:'course_service/visit', item: item31, user_id:)
        create(:'course_service/visit', item: item32, user_id:)
        create(:'course_service/result', item: item32, user_id:, dpoints: 10)
      end

      its(:status) { is_expected.to eq 200 }

      it 'adds some not published items in section 1 or 2' do
        skip 'todo'
      end

      context 'json' do
        subject { action; json }

        its(:size) { is_expected.to eq 3 }

        context 'section 1 progress' do
          subject { super()[0] }

          it_behaves_like 'a section progress', :section1
          its(['available']) { is_expected.to be_truthy }

          context 'items' do
            subject { super()['items'] }

            its(:size) { is_expected.to eq 5 }

            context 'item 1' do
              it_behaves_like 'a item', 0, :item11, user_state: 'new'
            end

            context 'item 2' do
              it_behaves_like 'a item', 1, :item12, user_state: 'graded', user_points: 5.0
            end

            context 'item 3' do
              it_behaves_like 'a item', 2, :item13, user_state: 'submitted', user_points: 8.2
            end

            context 'item 4' do
              it_behaves_like 'a item', 3, :item14, user_state: 'submitted', user_points: 2.0
            end

            context 'item 5' do
              it_behaves_like 'a item', 4, :item15, user_state: 'new'
            end
          end
        end

        context 'section 2 progress' do
          subject { super()[1] }

          it_behaves_like 'a section progress', :section2
          its(['available']) { is_expected.to be_truthy }

          context 'items' do
            subject { super()['items'] }

            its(:size) { is_expected.to eq 2 }

            context 'item 1' do
              it_behaves_like 'a item', 0, :item21, user_state: 'visited'
            end

            context 'item 2' do
              it_behaves_like 'a item', 1, :item22, user_state: 'visited'
            end
          end
        end

        context 'course progress' do
          subject { super()[2] }

          it_behaves_like 'a course progress'
        end
      end
    end

    #########################
    #### OPTIONAL SECTION ###
    #########################
    context 'with optional section' do
      let(:passed_datetime) { DateTime.now - 1.day }
      let(:next_datetime) { 1.day.from_now }
      let(:last_datetime) { DateTime.now + 2.days }
      let(:other_datetime) { DateTime.now + 1.hour }

      let(:section1_params) { {optional_section: true} }
      let(:item11_params) do
        {content_type: 'quiz', exercise_type: 'bonus',
                             max_dpoints: 10, submission_publishing_date: passed_datetime}
      end
      let(:item12_params) do
        {content_type: 'quiz', exercise_type: 'bonus',
                             max_dpoints: 70, submission_publishing_date: passed_datetime}
      end
      let(:item13_params) do
        {content_type: 'lti', exercise_type: 'bonus',
                             max_dpoints: 30, submission_publishing_date: next_datetime}
      end
      let(:item14_params) do
        {content_type: 'quiz', exercise_type: 'bonus',
                             max_dpoints: 80, submission_publishing_date: last_datetime}
      end
      let(:item15_params) { {content_type: 'quiz', exercise_type: 'selftest', max_dpoints: 89} }
      let(:item15) { create(:'course_service/item', {section: section1, position: 5}.merge(item15_params)) }
      let(:item16_params) { {content_type: 'video'} }
      let(:item16) { create(:'course_service/item', {section: section1, position: 6}.merge(item16_params)) }

      let(:item21_params) { {content_type: 'video'} }
      let(:item22_params) do
        {content_type: 'quiz', exercise_type: 'bonus',
                             max_dpoints: 120}
      end

      let(:item32_params) do
        {content_type: 'quiz', exercise_type: 'main',
                             max_dpoints: 200}
      end
      let(:item33_params) { {content_type: 'quiz', exercise_type: 'selftest', max_dpoints: 45} }
      let(:item33) { create(:'course_service/item', {section: section3, position: 3}.merge(item33_params)) }

      before do
        item11; item12; item13; item14; item15; item16
        create(:'course_service/visit', item: item14, user_id: other_user_id)
        create(:'course_service/result', item: item14, user_id: other_user_id, dpoints: 3)
        create(:'course_service/visit', item: item12, user_id:)
        create(:'course_service/result', item: item12, user_id:, dpoints: 50)
        create(:'course_service/visit', item: item13, user_id:)
        create(:'course_service/result', item: item13, user_id:, dpoints: 82)
        create(:'course_service/visit', item: item14, user_id:)
        create(:'course_service/result', item: item14, user_id:, dpoints: 20)
        create(:'course_service/visit', item: item15, user_id:)
        create(:'course_service/result', item: item15, user_id:, dpoints: 33)
        item21; item22
        create(:'course_service/visit', item: item22, user_id:)
        create(:'course_service/result', item: item22, user_id:, dpoints: 64)
        item31; item32; item33
        create(:'course_service/visit', item: item31, user_id:)
        create(:'course_service/visit', item: item32, user_id:)
        create(:'course_service/result', item: item32, user_id:, dpoints: 150)

        create(:'course_service/visit', item: item33, user_id:)
        create(:'course_service/result', item: item33, user_id:, dpoints: 21)
      end

      its(:status) { is_expected.to eq 200 }

      context 'json' do
        subject { action; json }

        its(:size) { is_expected.to eq 4 }

        context 'section 1 progress' do
          subject { super()[0] }

          it_behaves_like 'a section progress', :section1
          its(['available']) { is_expected.to be_truthy }

          context 'items' do
            subject { super()['items'] }

            its(:size) { is_expected.to eq 6 }

            context 'item 1' do
              it_behaves_like 'a item', 0, :item11, user_state: 'new'
            end

            context 'item 2' do
              it_behaves_like 'a item', 1, :item12, user_state: 'graded', user_points: 5.0
            end

            context 'item 3' do
              it_behaves_like 'a item', 2, :item13, user_state: 'submitted', user_points: 8.2
            end

            context 'item 4' do
              it_behaves_like 'a item', 3, :item14, user_state: 'submitted', user_points: 2.0
            end

            context 'item 5' do
              it_behaves_like 'a item', 4, :item15, user_state: 'graded', user_points: 3.3
            end

            context 'item 6' do
              it_behaves_like 'a item', 5, :item16, user_state: 'new'
            end
          end
        end

        context 'section 2 progress' do
          subject { super()[1] }

          it_behaves_like 'a section progress', :section2
          its(['available']) { is_expected.to be_truthy }

          context 'items' do
            subject { super()['items'] }

            its(:size) { is_expected.to eq 2 }

            context 'item 1' do
              it_behaves_like 'a item', 0, :item21, user_state: 'new'
            end

            context 'item 2' do
              it_behaves_like 'a item', 1, :item22, user_state: 'graded', user_points: 6.4
            end
          end
        end

        context 'section 3 progress' do
          subject { super()[2] }

          it_behaves_like 'a section progress', :section3
          its(['available']) { is_expected.to be_truthy }

          context 'items' do
            subject { super()['items'] }

            its(:size) { is_expected.to eq 3 }

            context 'item 1' do
              it_behaves_like 'a item', 0, :item31, user_state: 'visited'
            end

            context 'item 2' do
              it_behaves_like 'a item', 1, :item32, user_state: 'graded', user_points: 15.0
            end

            context 'item 3' do
              it_behaves_like 'a item', 2, :item33, user_state: 'graded', user_points: 2.1
            end
          end
        end

        context 'course progress' do
          subject { super()[3] }

          it_behaves_like 'a course progress'
        end
      end
    end
  end
end

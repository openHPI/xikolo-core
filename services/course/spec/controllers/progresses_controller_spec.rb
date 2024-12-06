# frozen_string_literal: true

require 'spec_helper'

describe ProgressesController, type: :controller do
  subject { action; response }

  let(:json) { JSON.parse response.body }
  let(:default_params) { {format: 'json'} }

  let(:action) { get :index, params: {course_id: course.id, user_id:} }

  let!(:course) { create(:course) }
  let(:user_id) { generate(:user_id) }
  let(:other_user_id) { generate(:user_id) }

  let(:section1_params) { {id: '00000002-3100-4444-9999-000000000001'} }
  let(:section1) { create(:section, {course:, position: 1, start_date: 10.days.ago.iso8601}.merge(section1_params)) }
  let(:item11_params) { {} }
  let(:item11) { create(:item, {section: section1, position: 1}.merge(item11_params)) }
  let(:item12_params) { {} }
  let(:item12) { create(:item, {section: section1, position: 2}.merge(item12_params)) }
  let(:item13_params) { {} }
  let(:item13) { create(:item, {section: section1, position: 3}.merge(item13_params)) }
  let(:item14_params) { {} }
  let(:item14) { create(:item, {section: section1, position: 4}.merge(item14_params)) }
  let(:item15_params) { {optional: true} }
  let(:item15) { create(:item, {section: section1, position: 10}.merge(item15_params)) }

  let(:section2_params) { {id: '00000002-3100-4444-9999-000000000002'} }
  let(:section2) { create(:section, {course:, position: 2, start_date: 10.days.ago.iso8601}.merge(section2_params)) }
  let(:item21_params) { {} }
  let(:item21) { create(:item, {section: section2, position: 1}.merge(item21_params)) }
  let(:item22_params) { {} }
  let(:item22) { create(:item, :proctored, {section: section2, position: 2}.merge(item22_params)) }

  let(:section3_params) { {id: '00000002-3100-4444-9999-000000000003'} }
  let(:section3) { create(:section, {course:, position: 3, start_date: 10.days.ago.iso8601}.merge(section3_params)) }
  let(:item31_params) { {} }
  let(:item31) { create(:item, {section: section3, position: 1}.merge(item31_params)) }
  let(:item32_params) { {} }
  let(:item32) { create(:item, {section: section3, position: 2}.merge(item32_params)) }

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
      expect(subject['parent']).to eq send(section).parent?
      expect(subject['parent_id']).to eq send(section).parent_id
    end
  end

  shared_examples 'the section1 progress' do |section1|
    it_behaves_like 'a section progress', section1

    context 'selftest_exercises' do
      subject { super()['selftest_exercises'] }

      it { is_expected.to include('submitted_points' => 13.5, 'graded_points' => 13.5, 'max_points' => 18) }
      it { is_expected.to include('submitted_exercises' => 2, 'total_exercises' => 3) }

      context 'items' do
        subject { super()['items'] }

        its(:size) { is_expected.to eq 3 }

        context 'item 1' do
          it_behaves_like 'a item', 0, :item12, user_state: 'graded', user_points: 5.5
        end

        context 'item 2' do
          it_behaves_like 'a item', 1, :item13, user_state: 'graded', user_points: 8.0
        end

        context 'item 3' do
          it_behaves_like 'a item', 2, :item14, user_state: 'new'
        end
      end
    end

    its(['visits']) { is_expected.to eq('total' => 4, 'user' => 2, 'percentage' => 50) }

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

    its(['visits']) { is_expected.to eq('total' => 2, 'user' => 2, 'percentage' => 100) }

    context 'selftest_exercises' do
      subject { super()['selftest_exercises'] }

      it { is_expected.to include('submitted_points' => 10, 'graded_points' => 10, 'max_points' => 12) }
      it { is_expected.to include('submitted_exercises' => 1, 'total_exercises' => 1) }

      context 'items' do
        subject { super()['items'] }

        its(:size) { is_expected.to eq 1 }

        context 'item 1' do
          it_behaves_like 'a item', 0, :item22, user_state: 'graded', user_points: 10.0
        end
      end
    end

    context 'main_exercises' do
      subject { super()['main_exercises'] }

      it { is_expected.to include('submitted_points' => 0, 'graded_points' => 0, 'max_points' => 1) }
      it { is_expected.to include('submitted_exercises' => 0, 'total_exercises' => 1) }

      context 'items' do
        subject { super()['items'] }

        its(:size) { is_expected.to eq 1 }

        context 'item 1' do
          it_behaves_like 'a item', 0, :item21, user_state: 'visited'
        end
      end
    end

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

    context 'selftest_exercises' do
      subject { super()['selftest_exercises'] }

      it { is_expected.to include 'submitted_points' => 2.0, 'graded_points' => 2.0, 'max_points' => 8.0 }
      it { is_expected.to include 'submitted_exercises' => 1, 'graded_exercises' => 1, 'total_exercises' => 1 }

      context 'items' do
        subject { super()['items'] }

        its(:size) { is_expected.to eq 1 }

        context 'item 1' do
          it_behaves_like 'a item', 0, :item31, user_state: 'graded', user_points: 2.0
        end
      end
    end

    its(['visits']) { is_expected.to eq 'total' => 2, 'user' => 1, 'percentage' => 50 }

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

    its(['visits']) { is_expected.to eq 'total' => 0, 'user' => 0, 'percentage' => 0 }

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
        'user_points',
        'time_effort'
      )
      expect(subject['id']).to eq item.id
      expect(subject['title']).to eq item.title
      expect(subject['exercise_type']).to eq item.exercise_type
      expect(subject['content_type']).to eq item.content_type
      expect(subject['user_state']).to eq opts[:user_state]
      expect(subject['optional']).to eq item.optional?
      expect(subject['max_points']).to eq item.max_dpoints&.fdiv 10
      expect(subject['user_points']).to eq opts[:user_points]
      expect(subject['time_effort']).to eq item.time_effort
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

          its(:keys) { is_expected.to match_array %w[kind visits resource_id] }
          its(['kind']) { is_expected.to eq 'course' }
          its(['visits']) { is_expected.to eq('total' => 0, 'user' => 0, 'percentage' => 0) }
        end
      end
    end

    ##############################
    context 'with item visits' do
      ##############################
      before do
        item11; item12; item13; item14; item15
        create(:visit, item: item11, user_id: other_user_id)
        create(:visit, item: item12, user_id:)
        create(:visit, item: item15, user_id:)
        create(:visit, item: item21, user_id:)
        item21; item22
      end

      its(:status) { is_expected.to eq 200 }

      context 'json' do
        subject { action; json }

        its(:size) { is_expected.to eq 3 }

        context 'section 1 progress' do
          subject { super()[0] }

          it_behaves_like 'a section progress', :section1

          its(['visits']) { is_expected.to eq('total' => 4, 'user' => 1, 'percentage' => 25) }

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

          its(['visits']) { is_expected.to eq('total' => 2, 'user' => 1, 'percentage' => 50) }

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
          its(['visits']) { is_expected.to eq('total' => 6, 'user' => 2, 'percentage' => 33) }
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
        create(:visit, item: item14, user_id: other_user_id)
        create(:result, item: item14, user_id: other_user_id, dpoints: 30)
        create(:visit, item: item13, user_id:)
        create(:result, item: item13, user_id:, dpoints: 80)
        create(:visit, item: item12, user_id:)
        create(:result, item: item12, user_id:, dpoints: 55)
        item21; item22
        create(:visit, item: item21, user_id:)
        create(:visit, item: item22, user_id:)
        create(:result, item: item22, user_id:, dpoints: 50)
        create(:result, item: item22, user_id:, dpoints: 100)
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
          its(['visits']) { is_expected.to eq('total' => 6, 'user' => 4, 'percentage' => 66) }

          context 'selftest_exercises' do
            subject { super()['selftest_exercises'] }

            it { is_expected.to include('submitted_points' => 23.5, 'graded_points' => 23.5, 'max_points' => 30) }
            it { is_expected.to include('submitted_exercises' => 3, 'graded_exercises' => 3, 'total_exercises' => 4) }

            context 'items' do
              subject { super()['items'] }

              it { is_expected.to be_nil }
            end
          end
        end

        context 'with alternative sections' do
          let!(:section_params) { {course:, start_date: 10.days.ago.iso8601} }
          let!(:parent_section) { create(:section, {id: '00000002-3100-4444-9999-000000000004', alternative_state: 'parent', position: 1}.merge(section_params)) }
          let!(:section_child_params) { {alternative_state: 'child', parent_id: parent_section.id}.merge(section_params) }
          let!(:section1) { create(:section, section_child_params.merge(position: 2, id: '00000002-3100-4444-9999-000000000001')) }
          let!(:section2) { create(:section, section_child_params.merge(position: 8, id: '00000002-3100-4444-9999-000000000002')) }
          let(:section3_params) { super().merge(position: 3) }
          let(:item31_params) { {content_type: 'quiz', exercise_type: 'selftest', max_dpoints: 80} }

          before do
            item31; item32
            create(:visit, item: item31, user_id:)
            create(:result, item: item31, user_id:, dpoints: 20)
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
              its(['visits']) { is_expected.to eq 'total' => 2, 'user' => 1, 'percentage' => 50 }

              its(['selftest_exercises']) do
                is_expected.to include \
                  'submitted_points' => 2.0,
                  'graded_points' => 2.0,
                  'max_points' => 8.0,
                  'submitted_exercises' => 1,
                  'graded_exercises' => 1,
                  'total_exercises' => 1
              end
            end
          end

          context 'with one section choice' do
            before do
              create(:section_choice,
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
              its(['visits']) { is_expected.to eq 'total' => 6, 'user' => 3, 'percentage' => 50 }

              its(['selftest_exercises']) do
                is_expected.to include \
                  'submitted_points' => 15.5,
                  'graded_points' => 15.5,
                  'max_points' => 26,
                  'submitted_exercises' => 3,
                  'graded_exercises' => 3,
                  'total_exercises' => 4
              end
            end
          end

          context 'with two section choices' do
            before do
              create(:section_choice,
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
                create(:enrollment,
                  user_id:,
                  course_id: course.id)

                Enrollment.with_learning_evaluation(
                  course.enrollments.where(user_id:)
                ).take!
              end

              it_behaves_like 'a course progress'
              its(['visits']) { is_expected.to eq 'total' => 6, 'user' => 3, 'percentage' => 50 }

              it 'learning evaluation should arrive at the same results' do
                create(:enrollment,
                  user_id:,
                  course_id: course.id)

                e = Enrollment.with_learning_evaluation(
                  course.enrollments.where(user_id:)
                ).take!

                expect(e).to have_attributes(
                  visits_total: 6,
                  visits_visited: 3,
                  visits_percentage: 50
                )
              end

              its(['selftest_exercises']) do
                is_expected.to include \
                  'submitted_points' => 15.5,
                  'graded_points' => 15.5,
                  'max_points' => 26,
                  'submitted_exercises' => 3,
                  'graded_exercises' => 3,
                  'total_exercises' => 4
              end
            end
          end
        end
      end
    end

    ###################################
    context 'with withhold results' do
      ###################################
      let(:passed_datetime) { DateTime.now - 1.day }
      let(:next_datetime) { 1.day.from_now }
      let(:last_datetime) { DateTime.now + 2.days }
      let(:item12_params) do
        {content_type: 'quiz', exercise_type: 'main',
                             max_dpoints: 70, submission_publishing_date: passed_datetime}
      end
      let(:item13_params) do
        {content_type: 'lti',  exercise_type: 'main',
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
        create(:visit, item: item14, user_id: other_user_id)
        create(:result, item: item14, user_id: other_user_id, dpoints: 30)
        create(:visit, item: item12, user_id:)
        create(:result, item: item12, user_id:, dpoints: 50)
        create(:visit, item: item13, user_id:)
        create(:result, item: item13, user_id:, dpoints: 82)
        create(:visit, item: item14, user_id:)
        create(:result, item: item14, user_id:, dpoints: 20)
        item21; item22
        create(:visit, item: item21, user_id:)
        create(:visit, item: item22, user_id:)
      end

      its(:status) { is_expected.to eq 200 }

      context 'json' do
        subject { action; json }

        its(:size) { is_expected.to eq 3 }

        context 'section 1 progress' do
          subject { super()[0] }

          it_behaves_like 'a section progress', :section1

          context 'main_exercises' do
            subject { super()['main_exercises'] }

            it { is_expected.to include('submitted_points' => 15.2, 'graded_points' => 5, 'max_points' => 18) }
            it { is_expected.to include('submitted_exercises' => 3, 'graded_exercises' => 1, 'total_exercises' => 3) }
            its(['next_publishing_date']) { is_expected.to eq next_datetime.utc.strftime('%Y-%m-%dT%H:%M:%SZ') }
            its(['last_publishing_date']) { is_expected.to eq last_datetime.utc.strftime('%Y-%m-%dT%H:%M:%SZ') }
          end

          context 'main_exercises items' do
            subject { super()['main_exercises']['items'] }

            its(:size) { is_expected.to eq 3 }

            context 'item 1' do
              it_behaves_like 'a item', 0, :item12, user_state: 'graded', user_points: 5.0
            end

            context 'item 2' do
              it_behaves_like 'a item', 1, :item13, user_state: 'submitted', user_points: 8.2
            end

            context 'item 3' do
              it_behaves_like 'a item', 2, :item14, user_state: 'submitted', user_points: 2.0
            end
          end

          its(['visits']) { is_expected.to eq('total' => 4, 'user' => 3, 'percentage' => 75) }

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

          its(['visits']) { is_expected.to eq('total' => 2, 'user' => 2, 'percentage' => 100) }

          context 'main_exercises' do
            subject { super()['main_exercises'] }

            it { is_expected.to include('submitted_points' => 0, 'graded_points' => 0, 'max_points' => 12) }
            it { is_expected.to include('submitted_exercises' => 0, 'total_exercises' => 1) }
            its(['next_publishing_date']) { is_expected.to be_nil }
            its(['last_publishing_date']) { is_expected.to be_nil }
          end

          context 'main_exercises items' do
            subject { super()['main_exercises']['items'] }

            its(:size) { is_expected.to eq 1 }

            context 'item 1' do
              it_behaves_like 'a item', 0, :item22, user_state: 'visited'
            end
          end

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
          its(['visits']) { is_expected.to eq('total' => 6, 'user' => 5, 'percentage' => 83) }

          context 'main_exercises' do
            subject { super()['main_exercises'] }

            it { is_expected.to include('submitted_points' => 15.2, 'graded_points' => 5, 'max_points' => 30) }
            it { is_expected.to include('submitted_exercises' => 3, 'graded_exercises' => 1, 'total_exercises' => 4) }

            context 'items' do
              subject { super()['items'] }

              it { is_expected.to be_nil }
            end
          end
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
        {content_type: 'lti',  exercise_type: 'main',
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
        create(:visit, item: item14, user_id: other_user_id)
        create(:result, item: item14, user_id: other_user_id, dpoints: 3)
        create(:visit, item: item12, user_id:)
        create(:result, item: item12, user_id:, dpoints: 50)
        create(:visit, item: item13, user_id:)
        create(:result, item: item13, user_id:, dpoints: 82)
        create(:visit, item: item14, user_id:)
        create(:result, item: item14, user_id:, dpoints: 20)
        item21; item22
        create(:visit, item: item21, user_id:)
        create(:visit, item: item22, user_id:)
        item31; item32
        create(:visit, item: item31, user_id:)
        create(:visit, item: item32, user_id:)
        create(:result, item: item32, user_id:, dpoints: 100)
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

          context 'main_exercises' do
            subject { super()['main_exercises'] }

            it { is_expected.to include('submitted_points' => 15.2, 'graded_points' => 5, 'max_points' => 18) }
            it { is_expected.to include('submitted_exercises' => 3, 'graded_exercises' => 1, 'total_exercises' => 3) }
            its(['next_publishing_date']) { is_expected.to eq next_datetime.utc.strftime('%Y-%m-%dT%H:%M:%SZ') }
            its(['last_publishing_date']) { is_expected.to eq last_datetime.utc.strftime('%Y-%m-%dT%H:%M:%SZ') }
          end

          context 'main_exercises items' do
            subject { super()['main_exercises']['items'] }

            its(:size) { is_expected.to eq 3 }

            context 'item 1' do
              it_behaves_like 'a item', 0, :item12, user_state: 'graded', user_points: 5.0
            end

            context 'item 2' do
              it_behaves_like 'a item', 1, :item13, user_state: 'submitted', user_points: 8.2
            end

            context 'item 3' do
              it_behaves_like 'a item', 2, :item14, user_state: 'submitted', user_points: 2.0
            end
          end

          its(['visits']) { is_expected.to eq('total' => 4, 'user' => 3, 'percentage' => 75) }

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

          its(['visits']) { is_expected.to eq('total' => 2, 'user' => 2, 'percentage' => 100) }

          context 'main_exercises' do
            subject { super()['main_exercises'] }

            it { is_expected.to include('submitted_points' => 0, 'graded_points' => 0, 'max_points' => 12) }
            it { is_expected.to include('submitted_exercises' => 0, 'graded_exercises' => 0, 'total_exercises' => 1) }
            its(['next_publishing_date']) { is_expected.to be_nil }
            its(['last_publishing_date']) { is_expected.to be_nil }
          end

          context 'main_exercises items' do
            subject { super()['main_exercises']['items'] }

            its(:size) { is_expected.to eq 1 }

            context 'item 1' do
              it_behaves_like 'a item', 0, :item22, user_state: 'visited'
            end
          end

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
          its(:keys) { is_expected.to match_array %w[kind title available optional resource_id description parent parent_id position alternative_state discarded required_section_ids] }
        end

        context 'course progress' do
          subject { super()[3] }

          it_behaves_like 'a course progress'
          its(['visits']) { is_expected.to eq('total' => 6, 'user' => 5, 'percentage' => 83) }

          context 'main_exercises' do
            subject { super()['main_exercises'] }

            it { is_expected.to include('submitted_points' => 15.2, 'graded_points' => 5, 'max_points' => 30) }
            it { is_expected.to include('submitted_exercises' => 3, 'graded_exercises' => 1, 'total_exercises' => 4) }

            context 'items' do
              subject { super()['items'] }

              it { is_expected.to be_nil }
            end
          end
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
        {content_type: 'lti',  exercise_type: 'main',
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
        create(:visit, item: item14, user_id: other_user_id)
        create(:result, item: item14, user_id: other_user_id, dpoints: 3)
        create(:visit, item: item12, user_id:)
        create(:result, item: item12, user_id:, dpoints: 50)
        create(:visit, item: item13, user_id:)
        create(:result, item: item13, user_id:, dpoints: 82)
        create(:visit, item: item14, user_id:)
        create(:result, item: item14, user_id:, dpoints: 20)
        item21; item22
        create(:visit, item: item21, user_id:)
        create(:visit, item: item22, user_id:)
        item31; item32
        create(:visit, item: item31, user_id:)
        create(:visit, item: item32, user_id:)
        create(:result, item: item32, user_id:, dpoints: 10)
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

          context 'main_exercises' do
            subject { super()['main_exercises'] }

            it { is_expected.to include('submitted_points' => 15.2, 'graded_points' => 5, 'max_points' => 18) }
            it { is_expected.to include('submitted_exercises' => 3, 'graded_exercises' => 1, 'total_exercises' => 3) }
            its(['next_publishing_date']) { is_expected.to eq next_datetime.utc.strftime('%Y-%m-%dT%H:%M:%SZ') }
            its(['last_publishing_date']) { is_expected.to eq last_datetime.utc.strftime('%Y-%m-%dT%H:%M:%SZ') }
          end

          context 'main_exercises items' do
            subject { super()['main_exercises']['items'] }

            its(:size) { is_expected.to eq 3 }

            context 'item 1' do
              it_behaves_like 'a item', 0, :item12, user_state: 'graded', user_points: 5.0
            end

            context 'item 2' do
              it_behaves_like 'a item', 1, :item13, user_state: 'submitted', user_points: 8.2
            end

            context 'item 3' do
              it_behaves_like 'a item', 2, :item14, user_state: 'submitted', user_points: 2.0
            end
          end

          its(['visits']) { is_expected.to eq('total' => 4, 'user' => 3, 'percentage' => 75) }

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

          its(['visits']) { is_expected.to eq('total' => 2, 'user' => 2, 'percentage' => 100) }

          context 'main_exercises' do
            subject { super()['main_exercises'] }

            it { is_expected.to include('submitted_points' => 0, 'graded_points' => 0, 'max_points' => 12) }
            it { is_expected.to include('submitted_exercises' => 0, 'total_exercises' => 1) }
            its(['next_publishing_date']) { is_expected.to be_nil }
            its(['last_publishing_date']) { is_expected.to be_nil }
          end

          context 'main_exercises items' do
            subject { super()['main_exercises']['items'] }

            its(:size) { is_expected.to eq 1 }

            context 'item 1' do
              it_behaves_like 'a item', 0, :item22, user_state: 'visited'
            end
          end

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
          its(['visits']) { is_expected.to eq('total' => 6, 'user' => 5, 'percentage' => 83) }

          context 'main_exercises' do
            subject { super()['main_exercises'] }

            it { is_expected.to include('submitted_points' => 15.2, 'graded_points' => 5, 'max_points' => 30) }
            it { is_expected.to include('submitted_exercises' => 3, 'graded_exercises' => 1, 'total_exercises' => 4) }

            context 'items' do
              subject { super()['items'] }

              it { is_expected.to be_nil }
            end
          end
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
        {content_type: 'lti',  exercise_type: 'bonus',
                             max_dpoints: 30, submission_publishing_date: next_datetime}
      end
      let(:item14_params) do
        {content_type: 'quiz', exercise_type: 'bonus',
                             max_dpoints: 80, submission_publishing_date: last_datetime}
      end
      let(:item15_params) { {content_type: 'quiz', exercise_type: 'selftest', max_dpoints: 89} }
      let(:item15) { create(:item, {section: section1, position: 5}.merge(item15_params)) }
      let(:item16_params) { {content_type: 'video'} }
      let(:item16) { create(:item, {section: section1, position: 6}.merge(item16_params)) }

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
      let(:item33) { create(:item, {section: section3, position: 3}.merge(item33_params)) }

      before do
        item11; item12; item13; item14; item15; item16
        create(:visit, item: item14, user_id: other_user_id)
        create(:result, item: item14, user_id: other_user_id, dpoints: 3)
        create(:visit, item: item12, user_id:)
        create(:result, item: item12, user_id:, dpoints: 50)
        create(:visit, item: item13, user_id:)
        create(:result, item: item13, user_id:, dpoints: 82)
        create(:visit, item: item14, user_id:)
        create(:result, item: item14, user_id:, dpoints: 20)
        create(:visit, item: item15, user_id:)
        create(:result, item: item15, user_id:, dpoints: 33)
        item21; item22
        create(:visit, item: item22, user_id:)
        create(:result, item: item22, user_id:, dpoints: 64)
        item31; item32; item33
        create(:visit, item: item31, user_id:)
        create(:visit, item: item32, user_id:)
        create(:result, item: item32, user_id:, dpoints: 150)

        create(:visit, item: item33, user_id:)
        create(:result, item: item33, user_id:, dpoints: 21)
      end

      its(:status) { is_expected.to eq 200 }

      context 'json' do
        subject { action; json }

        its(:size) { is_expected.to eq 4 }

        context 'section 1 progress' do
          subject { super()[0] }

          it_behaves_like 'a section progress', :section1
          its(['available']) { is_expected.to be_truthy }
          its(['optional']) { is_expected.to be_truthy }

          context 'selftest_exercises' do
            subject { super()['selftest_exercises'] }

            it { is_expected.to include('submitted_points' => 3.3, 'graded_points' => 3.3, 'max_points' => 8.9) }
            it { is_expected.to include('submitted_exercises' => 1, 'graded_exercises' => 1, 'total_exercises' => 1) }
            its(['next_publishing_date']) { is_expected.to be_nil }
            its(['last_publishing_date']) { is_expected.to be_nil }
          end

          context 'selftest_exercises items' do
            subject { super()['selftest_exercises']['items'] }

            its(:size) { is_expected.to eq 1 }

            context 'item 1' do
              it_behaves_like 'a item', 0, :item15, user_state: 'graded', user_points: 3.3
            end
          end

          its(['main_exercises']) { is_expected.to be_nil }

          context 'bonus_exercises' do
            subject { super()['bonus_exercises'] }

            it { is_expected.to include('submitted_points' => 15.2, 'graded_points' => 5.0, 'max_points' => 19) }
            it { is_expected.to include('submitted_exercises' => 3, 'graded_exercises' => 1, 'total_exercises' => 4) }
            its(['next_publishing_date']) { is_expected.to eq next_datetime.utc.strftime('%Y-%m-%dT%H:%M:%SZ') }
            its(['last_publishing_date']) { is_expected.to eq last_datetime.utc.strftime('%Y-%m-%dT%H:%M:%SZ') }
          end

          context 'bonus_exercises items' do
            subject { super()['bonus_exercises']['items'] }

            its(:size) { is_expected.to eq 4 }

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

          its(['visits']) { is_expected.to eq('total' => 6, 'user' => 4, 'percentage' => 66) }

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
          its(['optional']) { is_expected.to be_falsey }

          its(['visits']) { is_expected.to eq('total' => 2, 'user' => 1, 'percentage' => 50) }

          its(['selftest_exercises']) { is_expected.to be_nil }

          context 'bonus_exercises' do
            subject { super()['bonus_exercises'] }

            it { is_expected.to include('submitted_points' => 6.4, 'graded_points' => 6.4, 'max_points' => 12.0) }
            it { is_expected.to include('submitted_exercises' => 1, 'graded_exercises' => 1, 'total_exercises' => 1) }
            its(['next_publishing_date']) { is_expected.to be_nil }
            its(['last_publishing_date']) { is_expected.to be_nil }
          end

          context 'bonus_exercises items' do
            subject { super()['bonus_exercises']['items'] }

            its(:size) { is_expected.to eq 1 }

            context 'item 1' do
              it_behaves_like 'a item', 0, :item22, user_state: 'graded', user_points: 6.4
            end
          end

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
          its(['optional']) { is_expected.to be_falsey }

          context 'selftest_exercises' do
            subject { super()['selftest_exercises'] }

            it { is_expected.to include('submitted_points' => 2.1, 'graded_points' => 2.1, 'max_points' => 4.5) }
            it { is_expected.to include('submitted_exercises' => 1, 'graded_exercises' => 1, 'total_exercises' => 1) }
            its(['next_publishing_date']) { is_expected.to be_nil }
            its(['last_publishing_date']) { is_expected.to be_nil }
          end

          context 'selftest_exercises items' do
            subject { super()['selftest_exercises']['items'] }

            its(:size) { is_expected.to eq 1 }

            context 'item 1' do
              it_behaves_like 'a item', 0, :item33, user_state: 'graded', user_points: 2.1
            end
          end

          context 'main_exercises' do
            subject { super()['main_exercises'] }

            it { is_expected.to include('submitted_points' => 15.0, 'graded_points' => 15.0, 'max_points' => 20.0) }
            it { is_expected.to include('submitted_exercises' => 1, 'graded_exercises' => 1, 'total_exercises' => 1) }
            its(['next_publishing_date']) { is_expected.to be_nil }
            its(['last_publishing_date']) { is_expected.to be_nil }
          end

          context 'main_exercises items' do
            subject { super()['main_exercises']['items'] }

            its(:size) { is_expected.to eq 1 }

            context 'item 1' do
              it_behaves_like 'a item', 0, :item32, user_state: 'graded', user_points: 15.0
            end
          end

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
          its(['visits']) { is_expected.to eq('total' => 5, 'user' => 4, 'percentage' => 80) }

          context 'selftest_exercises' do
            subject { super()['selftest_exercises'] }

            it { is_expected.to include('submitted_points' => 2.1, 'graded_points' => 2.1, 'max_points' => 4.5) }
            it { is_expected.to include('submitted_exercises' => 1, 'graded_exercises' => 1, 'total_exercises' => 1) }

            context 'items' do
              subject { super()['items'] }

              it { is_expected.to be_nil }
            end
          end

          context 'bonus_exercises' do
            subject { super()['bonus_exercises'] }

            it { is_expected.to include('submitted_points' => 21.6, 'graded_points' => 11.4, 'max_points' => 31.0) }
            it { is_expected.to include('submitted_exercises' => 4, 'graded_exercises' => 2, 'total_exercises' => 5) }

            context 'items' do
              subject { super()['items'] }

              it { is_expected.to be_nil }
            end
          end

          context 'main_exercises' do
            subject { super()['main_exercises'] }

            it { is_expected.to include('submitted_points' => 15.0, 'graded_points' => 15.0, 'max_points' => 20.0) }
            it { is_expected.to include('submitted_exercises' => 1, 'graded_exercises' => 1, 'total_exercises' => 1) }

            context 'items' do
              subject { super()['items'] }

              it { is_expected.to be_nil }
            end
          end
        end
      end
    end
  end
end

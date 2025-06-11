# frozen_string_literal: true

require 'spec_helper'

##
# These comparison specs are more or less an exact copy of:
# spec/controllers/enrollments_controller_spec.rb
# GET 'index' with learning evaluation
#
describe EnrollmentsController, type: :controller do
  subject(:learning_evaluation) do
    # Create the enrollment after the course structure has been created to
    # trigger an update of the persisted learning evaluation. There will be
    # a manual trigger in the UI for teachers for this purpose (XI-5230).
    enrollment

    action.call
    json.first
  end

  variant 'Persisted evaluation' do
    let(:action) { -> { get :index, params: {evaluated: 'true', user_id:} } }
    let(:variant_before) do
      xi_config <<~YML
        persisted_learning_evaluation: true
      YML
    end

    around {|example| Sidekiq::Testing.inline!(&example) }
  end

  variant 'Computed evaluation' do
    let(:action) { -> { get :index, params: {learning_evaluation: 'true', user_id:} } }
    let(:variant_before) do
      # noop
    end
  end

  variant 'Computed evaluation (configured to read from persisted evaluation)' do
    let(:action) { -> { get :index, params: {learning_evaluation: 'true', user_id:} } }
    let(:variant_before) do
      xi_config <<~YML
        persisted_learning_evaluation:
          write: true
          read: true
      YML
    end

    around {|example| Sidekiq::Testing.inline!(&example) }
  end

  variant 'Computed evaluation (with silent comparison to persisted evaluation)' do
    let(:action) { -> { get :index, params: {learning_evaluation: 'true', user_id:} } }
    let(:variant_before) do
      xi_config <<~YML
        persisted_learning_evaluation:
          write: true
          read: 100
          legacy_courses:
            - #{course.id}
      YML

      # Comparison mismatches (expected, see skipped test) will be sent to S3
      stub_request(:put, %r{https://s3.xikolo.de/xikolo-scientist/experiments/persisted-learning-evaluation/mismatches/.+\.json})
        .to_return(status: 200)
    end

    around {|example| Sidekiq::Testing.inline!(&example) }

    # We'd typically want to raise if Scientist detects mismatches.
    # Here, we have one narrowly-defined edge case that should not affect end users.
    # Also, these are *comparison* specs aimed at ensuring the user-visible behavior
    # is the same (which is the case because only the control variant is exposed).
    # Thus, we keep mismatches to ourselves here.
    around do |example|
      original = Experiment.raise_on_mismatches?
      Experiment.raise_on_mismatches = false
      example.run
    ensure
      Experiment.raise_on_mismatches = original
    end
  end

  let(:json) { JSON.parse(response.body) }
  let(:default_params) { {format: 'json'} }

  let(:user_id) { generate(:user_id) }
  let(:enrollment) { create(:enrollment, course:, user_id:, completed:) }
  let(:completed) { nil }

  # Course content
  let(:course_opts) { {records_released:, start_date: 6.weeks.ago, end_date: Time.zone.now} }
  let(:course) { create(:course, course_opts) }
  let(:records_released) { false }

  let(:section1_params) { {start_date: 10.days.ago.iso8601} }
  let(:section1) { create(:section, {course:, position: 1}.merge(section1_params)) }
  let(:item11_params) { {} }
  let!(:item11) { create(:item, {section: section1, position: 1}.merge(item11_params)) }
  let(:item12_params) { {} }
  let!(:item12) { create(:item, {section: section1, position: 2}.merge(item12_params)) }
  let(:item13_params) { {content_type: 'quiz', exercise_type: 'main', max_dpoints: 50} }
  let!(:item13) { create(:item, {section: section1, position: 3}.merge(item13_params)) }
  let(:item14_params) { {content_type: 'quiz', exercise_type: 'bonus', max_dpoints: 70} }
  let!(:item14) { create(:item, :proctored, {section: section1, position: 4}.merge(item14_params)) }
  let(:item15_params) { {content_type: 'quiz', exercise_type: 'main', max_dpoints: 70, published: false} }

  let(:section2_params) { {start_date: 10.days.ago.iso8601} }
  let(:section2) { create(:section, {course:, position: 2}.merge(section2_params)) }
  let(:item21_params) { {content_type: 'quiz', exercise_type: 'main', max_dpoints: 100} }
  let!(:item21) { create(:item, :proctored, {section: section2, position: 1}.merge(item21_params)) }
  let(:item22_params) { {content_type: 'lti', exercise_type: 'main', max_dpoints: 50} }
  let!(:item22) { create(:item, {section: section2, position: 2}.merge(item22_params)) }
  let(:item23_params) { {content_type: 'lti', exercise_type: 'selftest', max_dpoints: 70, published: false} }
  let(:item24_params) { {content_type: 'video', published: false} }

  let(:section3_params) { {start_date: 10.days.ago.iso8601} }
  let(:section3) { create(:section, {course:, position: 3, published: false}.merge(section3_params)) }
  let(:item32_params) { {content_type: 'quiz', exercise_type: 'bonus', max_dpoints: 30} }
  let!(:item32) { create(:item, {section: section3, position: 2}.merge(item32_params)) }
  let(:item33_params) { {content_type: 'video'} }
  let!(:item33) { create(:item, {section: section3, position: 3}.merge(item33_params)) }

  before do
    # Specifying a native `before` blocks here and in variants leads to a
    # confusing execution order. Also, Rubocop will legitimately complain.
    variant_before

    create(:item, {section: section1, position: 5}.merge(item15_params))

    create(:item, {section: section2, position: 3}.merge(item23_params))
    create(:item, {section: section2, position: 4}.merge(item24_params))
  end

  with_all do
    context 'with section with 0 maximal points' do
      let(:item21_params) { {content_type: 'quiz', exercise_type: 'main', max_dpoints: 0} }
      let(:item22) { {} }

      it 'does not fail' do
        expect(learning_evaluation).not_to be_nil
      end
    end

    context 'completed_at date' do
      subject(:completed_at) { learning_evaluation['completed_at'] }

      let(:action) { -> { get :index, params: {user_id:, course_id: course.id, learning_evaluation: 'true'} } }

      let(:records_released) { true }
      let(:last_graded_item_date) { Time.zone.now }

      context 'records not released' do
        let(:records_released) { false }

        it 'is nil' do
          expect(completed_at).to be_nil
        end
      end

      context 'last graded item is main quiz' do
        before do
          create(:result, item: item13, user_id:, dpoints: 50, created_at: (last_graded_item_date - 1.day))
          create(:result, item: item21, user_id:, dpoints: 100, created_at: last_graded_item_date)
        end

        it 'is submission date of item21' do
          expect(Time.parse(completed_at).utc.to_s).to eq(last_graded_item_date.utc.to_s)
        end
      end

      context 'last graded item is bonus quiz' do
        before do
          create(:result, item: item13, user_id:, dpoints: 50, created_at: (last_graded_item_date - 1.day))
          create(:result, item: item14, user_id:, dpoints: 100, created_at: last_graded_item_date)
        end

        it 'is submission date of item14' do
          expect(Time.parse(completed_at).utc.to_s).to eq(last_graded_item_date.utc.to_s)
        end
      end

      context 'last graded item is selftest' do
        let(:item11_params) { {content_type: 'quiz', exercise_type: 'selftest', max_dpoints: 10} }

        before do
          create(:result, item: item13, user_id:, dpoints: 50, created_at: (last_graded_item_date - 1.day))
          create(:result, item: item21, user_id:, dpoints: 100, created_at: last_graded_item_date)
          create(:result, item: item11, user_id:, dpoints: 10, created_at: (last_graded_item_date + 1.day))
        end

        it 'is submission date of item21' do
          expect(Time.parse(completed_at).utc.to_s).to eq(last_graded_item_date.utc.to_s)
        end
      end

      context 'last graded item is main lti' do
        let(:item11_params) { {content_type: 'quiz', exercise_type: 'selftest', max_dpoints: 10} }

        before do
          create(:result, item: item13, user_id:, dpoints: 50, created_at: (last_graded_item_date - 1.day))
          create(:result, item: item22, user_id:, dpoints: 100, created_at: last_graded_item_date)
        end

        it 'is submission date of item22' do
          expect(Time.parse(completed_at).utc.to_s).to eq(last_graded_item_date.utc.to_s)
        end
      end
    end

    context 'certificate types' do
      subject { super()['certificates'] }

      context 'without released certificates' do
        let(:records_released) { false }

        its(['confirmation_of_participation']) { is_expected.to be false }
        its(['record_of_achievement']) { is_expected.to be false }
        its(['certificate']) { is_expected.to be false }
        its(['transcript_of_records']) { is_expected.to be false }
      end

      context 'with released certificates' do
        let(:records_released) { true }

        context 'confirmation_of_participation' do
          subject { super()['confirmation_of_participation'] }

          context 'with less than 50% of visited items' do
            before do
              create(:visit, item: item13, user_id:)
              create(:visit, item: item21, user_id:)
            end

            it { is_expected.to be false }

            context 'but record of achievement' do
              before do
                create(:result, item: item13, user_id:, dpoints: 29)
                create(:result, item: item21, user_id:, dpoints: 71)
                create(:result, item: item21, user_id:, dpoints: 51)
              end

              it { is_expected.to be true }
            end
          end

          context 'with 50% of visited items' do
            before do
              create(:visit, item: item11, user_id:)
              create(:visit, item: item13, user_id:)
              create(:visit, item: item22, user_id:)
            end

            it { is_expected.to be true }
          end

          context 'with more then 50% of visited items' do
            before do
              create(:visit, item: item11, user_id:)
              create(:visit, item: item13, user_id:)
              create(:visit, item: item21, user_id:)
              create(:visit, item: item22, user_id:)
            end

            it { is_expected.to be true }
          end

          context 'with optional sections' do
            let(:section3_params) { super().merge published: true, optional_section: true }

            context 'with less than 50% of visited items' do
              before do
                create(:visit, item: item13, user_id:)
                create(:visit, item: item21, user_id:)
              end

              it { is_expected.to be false }
            end

            context 'with 50% of visited items' do
              before do
                create(:visit, item: item11, user_id:)
                create(:visit, item: item13, user_id:)
                create(:visit, item: item22, user_id:)
              end

              it { is_expected.to be true }
            end

            context 'with more then 50% of visited items' do
              before do
                create(:visit, item: item11, user_id:)
                create(:visit, item: item13, user_id:)
                create(:visit, item: item21, user_id:)
                create(:visit, item: item22, user_id:)
              end

              it { is_expected.to be true }
            end

            context 'with more then 50% of visited items (if optional items would be included)' do
              before do
                create(:visit, item: item11, user_id:)
                create(:visit, item: item13, user_id:)
                create(:visit, item: item32, user_id:)
                create(:visit, item: item33, user_id:)
              end

              it { is_expected.to be false }
            end
          end

          context 'with optional items' do
            let(:item11_params) { super().merge optional: true }

            context 'with less than 50% of visited items' do
              before do
                create(:visit, item: item21, user_id:)
                create(:visit, item: item22, user_id:)
              end

              it { is_expected.to be false }
            end

            context 'with less than 50% of visited items but optional item' do
              before do
                create(:visit, item: item11, user_id:)
                create(:visit, item: item21, user_id:)
                create(:visit, item: item22, user_id:)
              end

              it { is_expected.to be false }
            end

            context 'with 50% of visited items' do
              before do
                create(:visit, item: item13, user_id:)
                create(:visit, item: item21, user_id:)
                create(:visit, item: item22, user_id:)
              end

              it { is_expected.to be true }
            end
          end
        end

        context 'record_of_achievement' do
          subject { super()['record_of_achievement'] }

          context 'with less than 50% of archiveable points' do
            before do
              create(:result, item: item21, user_id:, dpoints: 71)
            end

            it { is_expected.to be false }
          end

          context 'with less than 50% of archiveable points but additional bonus points' do
            before do
              create(:result, item: item21, user_id:, dpoints: 71)
              create(:result, item: item14, user_id:, dpoints: 29)
              create(:result, item: item14, user_id:, dpoints: 15)
            end

            it { is_expected.to be true }
          end

          context 'with more then 50% archiveable points' do
            before do
              create(:result, item: item21, user_id:, dpoints: 95)
              create(:result, item: item22, user_id:, dpoints: 5)
              create(:result, item: item22, user_id:, dpoints: 45)
            end

            it { is_expected.to be true }
          end
        end

        context 'certificate' do
          subject { super()['certificate'] }

          # currently all false, due to missing implementation in other system parts

          context 'with less than 50% of archiveable points' do
            before do
              create(:result, item: item21, user_id:, dpoints: 71)
            end

            it { is_expected.to be false }
          end

          context 'with less than 50% of archiveable points but additional bonus points' do
            before do
              create(:result, item: item21, user_id:, dpoints: 71)
              create(:result, item: item14, user_id:, dpoints: 29)
            end

            it { is_expected.to be false }
          end

          context 'with more then 50% archiveable points' do
            before do
              create(:result, item: item21, user_id:, dpoints: 95)
              create(:result, item: item22, user_id:, dpoints: 45)
            end

            it { is_expected.to be false }
          end

          context 'with all archiveable points' do
            before do
              create(:result, item: item13, user_id:, dpoints: 50)
              create(:result, item: item21, user_id:, dpoints: 100)
              create(:result, item: item22, user_id:, dpoints: 50)
            end

            it { is_expected.to be false }
          end
        end
      end
    end

    context 'completed' do
      subject { super()['completed'] }

      shared_examples 'overridable bool with default to' do |dft|
        context 'per default' do
          let(:completed) { nil }

          it { is_expected.to be dft }
        end

        context 'when forced' do
          let(:completed) { true }

          it { is_expected.to be true }
        end

        context 'when removed' do
          let(:completed) { false }

          it { is_expected.to be false }
        end
      end

      context 'with less than 50% of archiveable points but additional bonus points' do
        before do
          create(:result, item: item21, user_id:, dpoints: 71)
          create(:result, item: item14, user_id:, dpoints: 29)
        end

        context 'with records_released' do
          let(:records_released) { true }

          context 'in an active course' do
            let(:course_opts) { super().merge end_date: 2.days.from_now, status: 'active' }

            it_behaves_like 'overridable bool with default to', true
          end

          context 'in an still active course' do
            let(:course_opts) { super().merge end_date: 2.days.ago, status: 'active', auto_archive: false }

            it_behaves_like 'overridable bool with default to', true
          end

          context 'in an auto archived course with active status' do
            let(:course_opts) { super().merge end_date: 2.days.ago, status: 'active' }

            it_behaves_like 'overridable bool with default to', true
          end

          context 'in an auto archived course with status archive' do
            let(:course_opts) { super().merge end_date: 2.days.ago, status: 'archive' }

            it_behaves_like 'overridable bool with default to', true
          end
        end

        context 'without records_released' do
          let(:records_released) { false }

          it_behaves_like 'overridable bool with default to', false
        end
      end

      context 'with less then 50% of archiveable points' do
        before do
          create(:result, item: item21, user_id:, dpoints: 71)
        end

        context 'with records_released' do
          let(:records_released) { true }

          it_behaves_like 'overridable bool with default to', false
        end

        context 'without records_released' do
          let(:records_released) { false }

          it_behaves_like 'overridable bool with default to', false
        end

        context 'but a confirmation of participation' do
          let(:records_released) { true }

          before do
            create(:visit, item: item11, user_id:)
            create(:visit, item: item13, user_id:)
            create(:visit, item: item21, user_id:)
            create(:visit, item: item22, user_id:)
          end

          context 'in an active course' do
            let(:course_opts) { super().merge end_date: 2.days.from_now, status: 'active' }

            it_behaves_like 'overridable bool with default to', false
          end

          context 'in an still active course' do
            let(:course_opts) { super().merge end_date: 2.days.ago, status: 'active', auto_archive: false }

            it_behaves_like 'overridable bool with default to', false
          end

          context 'in an auto archived course with status active' do
            let(:course_opts) { super().merge end_date: 2.days.ago, status: 'active' }

            it_behaves_like 'overridable bool with default to', true
          end

          context 'in an auto archived course with status archive' do
            let(:course_opts) { super().merge end_date: 2.days.ago, status: 'archive' }

            it_behaves_like 'overridable bool with default to', true
          end
        end
      end
    end

    context 'points' do
      subject(:points) { learning_evaluation['points'] }

      context 'without any results' do
        it { is_expected.to eq 'achieved' => 0.0, 'maximal' => 20.0, 'percentage' => 0.0 }
      end

      context 'with results but no bonus points' do
        before do
          create(:result, item: item21, user_id:, dpoints: 71)
        end

        it { is_expected.to eq 'achieved' => 7.1, 'maximal' => 20.0, 'percentage' => 35.5 }
      end

      context 'with results and bonus points' do
        before do
          create(:result, item: item14, user_id:, dpoints: 54)
          create(:result, item: item21, user_id:, dpoints: 71)
        end

        it { is_expected.to eq 'achieved' => 12.5, 'maximal' => 20.0, 'percentage' => 62.5 }
      end

      context 'with results and more bonus points then maximal points' do
        before do
          create(:result, item: item14, user_id:, dpoints: 65)
          create(:result, item: item21, user_id:, dpoints: 95)
          create(:result, item: item22, user_id:, dpoints: 50)
        end

        it { is_expected.to eq 'achieved' => 20.0, 'maximal' => 20.0, 'percentage' => 100.0 }
      end

      context 'with alternative sections' do
        let!(:parent_section) { create(:section, alternative_state: 'parent', course:) }
        let!(:alternative_section1) do
          create(:section, course:, alternative_state: 'child', parent_id: parent_section.id)
        end
        let(:item_a11_params) { {content_type: 'quiz', exercise_type: 'main', max_dpoints: 50} }
        let!(:item_a11) { create(:item, {section: alternative_section1}.merge(item_a11_params)) }
        let(:item_a12_params) { {content_type: 'quiz', exercise_type: 'bonus', max_dpoints: 30} }
        let!(:item_a12) { create(:item, {section: alternative_section1}.merge(item_a12_params)) }
        let!(:alternative_section2) do
          create(:section, course:, alternative_state: 'child', parent_id: parent_section.id)
        end
        let(:item_a21_params) { {content_type: 'quiz', exercise_type: 'main', max_dpoints: 60} }
        let!(:item_a21) { create(:item, {section: alternative_section2}.merge(item_a21_params)) }
        let(:item_a22_params) { {content_type: 'quiz', exercise_type: 'bonus', max_dpoints: 40} }
        let!(:item_a22) { create(:item, {section: alternative_section2}.merge(item_a22_params)) }

        before do
          create(:section_choice, section_id: parent_section.id,
            user_id:, choice_ids: [alternative_section1.id, alternative_section2.id])
        end

        context 'without any results' do
          it 'only includes alternative section with least max points' do
            expect(points).to eq 'achieved' => 0.0, 'maximal' => 25.0, 'percentage' => 0.0
          end
        end

        context 'with incomplete results and no bonus points' do
          before do
            create(:result, item: item_a11, user_id:, dpoints: 50)
            create(:result, item: item_a21, user_id:, dpoints: 50)
          end

          it 'only includes alternative section with highest graded percentage' do
            expect(points).to eq 'achieved' => 5.0, 'maximal' => 25.0, 'percentage' => 20.0
          end
        end

        context 'with complete results but no bonus points' do
          before do
            create(:result, item: item_a11, user_id:, dpoints: 50)
            create(:result, item: item_a21, user_id:, dpoints: 60)
          end

          it 'only includes alternative section with highest max points' do
            expect(points).to eq 'achieved' => 6.0, 'maximal' => 26.0, 'percentage' => 23.07
          end
        end

        context 'with incomplete results and bonus points in one alternative section' do
          before do
            create(:result, item: item_a11, user_id:, dpoints: 20)
            create(:result, item: item_a12, user_id:, dpoints: 30)
            create(:result, item: item_a21, user_id:, dpoints: 50)
          end

          it 'only includes alternative section with highest graded percentage' do
            expect(points).to eq 'achieved' => 5.0, 'maximal' => 25.0, 'percentage' => 20.0
          end
        end

        context 'with complete results and bonus points in one alternative section' do
          before do
            create(:result, item: item_a11, user_id:, dpoints: 50)
            create(:result, item: item_a12, user_id:, dpoints: 30)
            create(:result, item: item_a21, user_id:, dpoints: 50)
          end

          it 'only includes alternative section with highest graded percentage' do
            expect(points).to eq 'achieved' => 8.0, 'maximal' => 25.0, 'percentage' => 32.0
          end
        end

        context 'with complete results and bonus points' do
          before do
            create(:result, item: item_a11, user_id:, dpoints: 50)
            create(:result, item: item_a12, user_id:, dpoints: 30)
            create(:result, item: item_a21, user_id:, dpoints: 60)
            create(:result, item: item_a22, user_id:, dpoints: 40)
          end

          it 'only includes alternative section with highest max points' do
            expect(points).to eq 'achieved' => 10.0, 'maximal' => 26.0, 'percentage' => 38.46
          end
        end
      end

      context 'with optional sections' do
        let(:section3_params) { super().merge published: true, optional_section: true }

        context 'with results and bonus points' do
          before do
            create(:result, item: item14, user_id:, dpoints: 54)
            create(:result, item: item21, user_id:, dpoints: 71)
          end

          it { is_expected.to eq 'achieved' => 12.5, 'maximal' => 20.0, 'percentage' => 62.5 }
        end

        context 'with results and bonus points in optional section' do
          before do
            create(:result, item: item14, user_id:, dpoints: 54)
            create(:result, item: item21, user_id:, dpoints: 71)
            create(:result, item: item32, user_id:, dpoints: 13)
          end

          it { is_expected.to eq 'achieved' => 13.8, 'maximal' => 20.0, 'percentage' => 69.0 }
        end
      end
    end

    context 'visits' do
      subject(:visits) { learning_evaluation['visits'] }

      let(:item11_params) { super().merge optional: true }

      context 'without any visits' do
        it { is_expected.to eq 'visited' => 0, 'total' => 5, 'percentage' => 0.0 }
      end

      context 'with visits' do
        before do
          create(:visit, item: item21, user_id:)
        end

        it { is_expected.to eq 'visited' => 1, 'total' => 5, 'percentage' => 20.0 }
      end

      context 'with optional visit' do
        before do
          create(:visit, item: item11, user_id:)
          create(:visit, item: item21, user_id:)
        end

        it { is_expected.to eq 'visited' => 1, 'total' => 5, 'percentage' => 20.0 }
      end

      context 'with all (include optional) visits' do
        before do
          create(:visit, item: item11, user_id:)
          create(:visit, item: item12, user_id:)
          create(:visit, item: item13, user_id:)
          create(:visit, item: item14, user_id:)
          create(:visit, item: item21, user_id:)
          create(:visit, item: item22, user_id:)
        end

        it { is_expected.to eq 'visited' => 5, 'total' => 5, 'percentage' => 100.0 }
      end

      context 'with alternative sections' do
        let!(:parent_section) { create(:section, alternative_state: 'parent', course:) }
        let!(:alternative_section1) do
          create(:section, course:, alternative_state: 'child', parent_id: parent_section.id)
        end
        let!(:item_a11) { create(:item, section: alternative_section1) }
        let!(:item_a12) { create(:item, section: alternative_section1) }
        let!(:alternative_section2) do
          create(:section, course:, alternative_state: 'child', parent_id: parent_section.id)
        end
        let!(:item_a21) { create(:item, section: alternative_section2) }
        let!(:item_a22) { create(:item, section: alternative_section2) }
        let!(:item_a23) { create(:item, section: alternative_section2) }
        let!(:item_a24) { create(:item, section: alternative_section2) }

        before do
          create(:section_choice, section_id: parent_section.id,
            user_id:, choice_ids: [alternative_section1.id, alternative_section2.id])
        end

        context 'without any visits' do
          it 'only includes alternative section with least visits' do
            expect(visits).to eq 'visited' => 0, 'total' => 7, 'percentage' => 0.0
          end
        end

        context 'with different visit percentages' do
          it 'only includes alternative section with most visits (first one)' do
            create(:visit, item: item_a11, user_id:)
            create(:visit, item: item_a12, user_id:)
            create(:visit, item: item_a21, user_id:)
            expect(visits).to eq 'visited' => 2, 'total' => 7, 'percentage' => 28.57
          end

          it 'only includes alternative section with most visits (second one)' do
            create(:visit, item: item_a11, user_id:)
            create(:visit, item: item_a21, user_id:)
            create(:visit, item: item_a23, user_id:)
            create(:visit, item: item_a24, user_id:)
            expect(visits).to eq 'visited' => 3, 'total' => 9, 'percentage' => 33.33
          end
        end

        context 'with equal visit percentage' do
          before do
            create(:visit, item: item_a11, user_id:)
            create(:visit, item: item_a21, user_id:)
            create(:visit, item: item_a22, user_id:)
          end

          it 'only includes alternative section with most visits' do
            expect(visits).to eq 'visited' => 2, 'total' => 9, 'percentage' => 22.22
          end
        end
      end

      context 'with optional sections' do
        let(:section3_params) { super().merge published: true, optional_section: true }

        context 'with results and bonus points' do
          before do
            create(:visit, item: item14, user_id:)
            create(:visit, item: item21, user_id:)
          end

          it { is_expected.to eq 'visited' => 2, 'total' => 5, 'percentage' => 40.0 }
        end

        context 'with results and bonus points in optional section' do
          before do
            create(:visit, item: item14, user_id:)
            create(:visit, item: item21, user_id:)
            create(:visit, item: item32, user_id:)
          end

          it { is_expected.to eq 'visited' => 2, 'total' => 5, 'percentage' => 40.0 }
        end
      end
    end

    context 'quantile' do
      subject(:quantile) { learning_evaluation['quantile'] }

      context 'by default' do
        it { is_expected.to be_nil }
      end

      context 'with previously calculated quantile' do
        before { enrollment.update!(quantile: 0.98523) }

        it { is_expected.to eq 0.98523 }
      end

      context 'when on demand' do
        let(:records_released) { true }

        before { enrollment.update!(quantile: nil, forced_submission_date: 2.days.from_now) }

        it 'is nil without other enrollments' do
          expect(quantile).to be_nil
        end

        it 'is nil without enrollments with quantile' do
          create(:enrollment, course:)
          create(:enrollment, course:)
          expect(quantile).to be_nil
        end

        it 'is nil if we have not enough points for RoA' do
          create(:result, item: item13, user_id:, dpoints: 24)
          create(:result, item: item21, user_id:, dpoints: 75)

          expect(quantile).to be_nil
        end

        it 'is nil if our points are worse then all other quantiled points' do
          # we get 15P
          create(:result, item: item13, user_id:, dpoints: 50)
          create(:result, item: item21, user_id:, dpoints: 100)
          # other have 16P / 17P points
          create(:enrollment, course:, quantiled_user_dpoints: 160, quantile: 0)
          create(:enrollment, course:, quantiled_user_dpoints: 170, quantile: 1)
          expect(quantile).to be_nil
        end

        it 'gets quantile of a user with the same points' do
          # we get 15P
          create(:result, item: item13, user_id:, dpoints: 50)
          create(:result, item: item21, user_id:, dpoints: 100)
          create(:enrollment, course:, quantiled_user_dpoints: 130, quantile: 0)
          create(:enrollment, course:, quantiled_user_dpoints: 150, quantile: 0.7)
          create(:enrollment, course:, quantiled_user_dpoints: 170, quantile: 1)
          expect(quantile).to eq 0.7
        end

        it 'gets quantile of a the best user with lower points' do
          # we get 15P
          create(:result, item: item13, user_id:, dpoints: 50)
          create(:result, item: item21, user_id:, dpoints: 100)
          create(:enrollment, course:, quantiled_user_dpoints: 130, quantile: 0)
          create(:enrollment, course:, quantiled_user_dpoints: 149, quantile: 0.690)
          create(:enrollment, course:, quantiled_user_dpoints: 170, quantile: 1)
          expect(quantile).to eq 0.69
        end

        it 'gets quantile of a the best user with lower points (when we are the best)' do
          # we get 15P
          create(:result, item: item13, user_id:, dpoints: 50)
          create(:result, item: item21, user_id:, dpoints: 100)
          create(:enrollment, course:, quantiled_user_dpoints: 130, quantile: 0)
          create(:enrollment, course:, quantiled_user_dpoints: 149, quantile: 0.9)
          create(:enrollment, course:, quantiled_user_dpoints: 120, quantile: 0.5)
          expect(quantile).to eq 0.9
        end
      end
    end

    context 'and fixed learning evaluation' do
      let(:records_released) { true }

      context 'for the base case' do
        before do
          create(:fixed_learning_evaluation, user_id:, course_id: course.id,
            user_dpoints: 234, maximal_dpoints: 400, visits_percentage: 83.94)

          # This needs to be manually triggered for the persisted learning evaluation
          # whenever a fixed learning evaluation is created. This only happens in
          # theory, since this is legacy data that is read-only.
          LearningEvaluation::UpdateCourseProgressWorker
            .perform_async(course.id, user_id)
        end

        it 'matches result' do
          expect(learning_evaluation['certificates']).to eq(
            {
              'confirmation_of_participation' => true,
              'record_of_achievement' => true,
              'certificate' => false,
              'transcript_of_records' => false,
            }
          )

          # This is the only exception where the persisted evaluation differs from
          # the computed one: it ignores fixed evaluations for the achieved and
          # maximal points. However, this is fine, since only the percentage value
          # is used to calculate the achievement of RoAs.
          #
          # expect(learning_evaluation['points']).to eq(
          #   {
          #     'achieved' => 23.4,
          #     'maximal' => 40.0,
          #     'percentage' => 58.5,
          #   }
          # )

          expect(learning_evaluation['completed']).to be true
        end
      end

      context 'without 50% visits and points' do
        before do
          create(:visit, item: item11, user_id:)
          create(:visit, item: item13, user_id:)

          create(:fixed_learning_evaluation, user_id:, course_id: course.id,
            user_dpoints: 134, maximal_dpoints: 400, visits_percentage: 49.94)

          # This needs to be manually triggered for the persisted learning evaluation
          # whenever a fixed learning evaluation is created. This only happens in
          # theory, since this is legacy data that is read-only.
          LearningEvaluation::UpdateCourseProgressWorker
            .perform_async(course.id, user_id)
        end

        it 'matches result' do
          expect(learning_evaluation['certificates']).to eq(
            {
              'confirmation_of_participation' => false,
              'record_of_achievement' => false,
              'certificate' => false,
              'transcript_of_records' => false,
            }
          )
        end
      end

      context 'with 50% visits but without 50% of points' do
        before do
          create(:fixed_learning_evaluation, user_id:, course_id: course.id,
            user_dpoints: 134, maximal_dpoints: 400, visits_percentage: 50.94)

          # This needs to be manually triggered for the persisted learning evaluation
          # whenever a fixed learning evaluation is created. This only happens in
          # theory, since this is legacy data that is read-only.
          LearningEvaluation::UpdateCourseProgressWorker
            .perform_async(course.id, user_id)
        end

        it 'matches result' do
          expect(learning_evaluation['certificates']).to eq(
            {
              'confirmation_of_participation' => true,
              'record_of_achievement' => false,
              'certificate' => false,
              'transcript_of_records' => false,
            }
          )
        end
      end

      context 'with more visisted items than learning evaluation' do
        before do
          create(:visit, item: item11, user_id:)
          create(:visit, item: item13, user_id:)
          create(:visit, item: item21, user_id:)
          create(:visit, item: item22, user_id:)

          create(:fixed_learning_evaluation, user_id:, course_id: course.id,
            user_dpoints: 134, maximal_dpoints: 400, visits_percentage: 1.25)

          # This needs to be manually triggered for the persisted learning evaluation
          # whenever a fixed learning evaluation is created. This only happens in
          # theory, since this is legacy data that is read-only.
          LearningEvaluation::UpdateCourseProgressWorker
            .perform_async(course.id, user_id)
        end

        it 'matches result' do
          expect(learning_evaluation['certificates']).to eq(
            {
              'confirmation_of_participation' => true,
              'record_of_achievement' => false,
              'certificate' => false,
              'transcript_of_records' => false,
            }
          )
        end
      end
    end

    context 'without course content' do
      let(:empty_course) { create(:course, records_released: true) }

      before { enrollment.update!(course: empty_course) }

      it 'matches result' do
        expect(learning_evaluation['certificates']).to eq(
          {
            'confirmation_of_participation' => false,
            'record_of_achievement' => false,
            'certificate' => false,
            'transcript_of_records' => false,
          }
        )

        expect(learning_evaluation['completed']).to be false
      end
    end

    context 'with proctored enrollment' do
      let(:records_released) { true }

      before { enrollment.update!(proctored: true) }

      context 'enought points' do
        before do
          create(:visit, item: item11, user_id:)
          create(:visit, item: item13, user_id:)
          create(:visit, item: item21, user_id:)
          create(:visit, item: item22, user_id:)

          create(:result, item: item13, user_id:, dpoints: 29)
          create(:result, item: item21, user_id:, dpoints: 71, created_at: 1.second.ago)
          create(:result, item: item22, user_id:, dpoints: 71, created_at: 1.second.ago)
        end

        it 'matches result' do
          expect(learning_evaluation['certificates']).to eq(
            {
              'confirmation_of_participation' => true,
              'record_of_achievement' => true,
              'certificate' => true,
              'transcript_of_records' => false,
            }
          )

          expect(learning_evaluation['points']).to eq(
            {
              'achieved' => 17.1,
              'maximal' => 20.0,
              'percentage' => 85.5,
            }
          )

          expect(learning_evaluation['completed']).to be true
        end
      end

      context 'later more points' do
        before do
          create(:visit, item: item11, user_id:)
          create(:visit, item: item13, user_id:)
          create(:visit, item: item21, user_id:)
          create(:visit, item: item22, user_id:)

          create(:result, item: item13, user_id:, dpoints: 29)
          create(:result, item: item21, user_id:, dpoints: 5, created_at: 2.seconds.ago)
          create(:result, item: item21, user_id:, dpoints: 76, created_at: 1.second.ago)
        end

        it 'matches result' do
          expect(learning_evaluation['certificates']).to eq(
            {
              'confirmation_of_participation' => true,
              'record_of_achievement' => true,
              'certificate' => true,
              'transcript_of_records' => false,
            }
          )

          expect(learning_evaluation['points']).to eq(
            {
              'achieved' => 10.5,
              'maximal' => 20.0,
              'percentage' => 52.5,
            }
          )

          expect(learning_evaluation['completed']).to be true
        end
      end

      context 'later less points' do
        before do
          create(:visit, item: item11, user_id:)
          create(:visit, item: item13, user_id:)
          create(:visit, item: item21, user_id:)
          create(:visit, item: item22, user_id:)

          create(:result, item: item13, user_id:, dpoints: 29)
          create(:result, item: item21, user_id:, dpoints: 73, created_at: 2.seconds.ago)
          create(:result, item: item21, user_id:, dpoints: 5, created_at: 1.second.ago)
        end

        it 'matches result' do
          expect(learning_evaluation['certificates']).to eq(
            {
              'confirmation_of_participation' => true,
              'record_of_achievement' => false,
              'certificate' => false,
              'transcript_of_records' => false,
            }
          )

          expect(learning_evaluation['points']).to eq(
            {
              'achieved' => 3.4,
              'maximal' => 20.0,
              'percentage' => 17.0,
            }
          )

          expect(learning_evaluation['completed']).to be true
        end
      end
    end
  end
end

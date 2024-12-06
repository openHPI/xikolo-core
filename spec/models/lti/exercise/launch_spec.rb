# frozen_string_literal: true

require 'spec_helper'

describe 'LTI::Exercise#launch_for' do
  subject(:launch) { exercise.launch_for(user) }

  let(:user_id) { SecureRandom.uuid }
  let(:gradebook) { create(:lti_gradebook, exercise:, user_id:) }
  let(:provider) { create(:lti_provider, consumer_key: 'teambuilder-app', course_id:) }

  let(:user) do
    Xikolo::Common::Auth::CurrentUser.from_session(
      'permissions' => permissions,
      'features' => features,
      'user_id' =>  user_id,
      'user' => {'anonymous' => false, 'id' => user_id, 'email' => 'jsmith@example.com', 'name' => 'John Smith'},
      'masqueraded' => false
    )
  end

  let(:permissions) { [] }
  let(:features) { {} }

  let(:exercise) { create(:lti_exercise, provider:) }
  let(:course_id) { generate(:course_id) }
  let(:item_id) { generate(:item_id) }
  let(:submission_deadline) { nil }
  let!(:course) { create(:course, id: course_id, course_code: 'the-course', title: 'The Course', context_id: 'coursecontext') }
  let!(:section) { create(:section, course:) }
  let(:item) { create(:item, id: item_id, section:, content: exercise, submission_deadline:) }

  before { item }

  it 'includes course information' do
    expect(launch.data_hash).to include(
      'context_id' => course_id,
      'context_title' => 'The Course',
      'custom_course' => 'the-course'
    )
  end

  context 'with a global provider' do
    let(:provider) { create(:lti_provider, :global) }

    it 'includes course information' do
      expect(launch.data_hash).to include(
        'context_id' => course_id,
        'context_title' => 'The Course',
        'custom_course' => 'the-course'
      )
    end
  end

  it 'includes information about the exercise' do
    expect(launch.data_hash).to include(
      'resource_link_id' => exercise.id,
      'resource_link_title' => 'Exercise' # The exercise's title
    )
  end

  describe 'includes information about the user' do
    context 'when the LTI provider has unprotected privacy' do
      let(:provider) { create(:lti_provider, :unprotected, course_id:) }

      it 'includes user information' do
        expect(launch.data_hash).to include(
          'lis_person_contact_email_primary' => 'jsmith@example.com',
          'lis_person_name_family' => 'Mous',
          'lis_person_name_given' => 'Anony',
          'lis_person_name_full' => 'John Smith',
          'user_id' => user_id
        )
      end
    end

    context 'when the LTI provider has anonymized privacy (default)' do
      let(:provider) { create(:lti_provider, privacy: 'anonymized', course_id:) }

      it 'does not include user information' do
        expect(launch.data_hash).not_to include(
          'lis_person_contact_email_primary',
          'lis_person_name_family',
          'lis_person_name_given',
          'lis_person_name_full',
          'user_id'
        )
      end
    end

    context 'when the LTI provider has pseudonymized privacy' do
      let(:provider) { create(:lti_provider, :pseudonymized, course_id:) }

      it 'includes a subset of user information' do
        expect(launch.data_hash).not_to include(
          'lis_person_contact_email_primary',
          'lis_person_name_family',
          'lis_person_name_given'
        )
        expect(launch.data_hash).to include(
          'lis_person_name_full',
          'user_id'
        )
      end

      it 'pseudonymizes (SHA-256) an identifier and exposes that as user ID and full name' do
        hash = Digest::SHA256.hexdigest("#{provider.id}|#{user_id}")

        expect(launch.data_hash['lis_person_name_full']).to eq hash
        expect(launch.data_hash['user_id']).to eq hash
      end

      describe 'the hashed user ID' do
        let(:user2_id) { generate(:user_id) }
        let(:user2) do
          Xikolo::Common::Auth::CurrentUser.from_session(
            'permissions' => permissions,
            'features' => features,
            'user_id' =>  user2_id,
            'user' => {'anonymous' => false, 'id' => user2_id, 'email' => 'test2@xikolo.de', 'name' => 'Amazing Joe'},
            'masqueraded' => false
          )
        end
        let(:permissions) { [] }
        let(:features) { {} }

        let(:provider) { create(:lti_provider, :pseudonymized, :global) }
        let(:exercise) { create(:lti_exercise, provider:) }

        let(:same_provider_exercise) { create(:lti_exercise, provider:) }
        let(:same_provider_section) { create(:section, course:) }
        let(:same_provider_item) { create(:item, section: same_provider_section, content: same_provider_exercise) }

        let(:different_course_same_provider_exercise) { create(:lti_exercise, provider:) }
        let(:different_course_same_provider_section) { create(:section, course: course2) }
        let(:different_course_same_provider_item) { create(:item, section: different_course_same_provider_section, content: different_course_same_provider_exercise) }

        let(:course_provider) { create(:lti_provider, :pseudonymized, course_id:) }
        let(:different_provider_exercise) { create(:lti_exercise, provider: course_provider) }
        let(:different_provider_section) { create(:section, course:) }
        let(:different_provider_item) { create(:item, section: different_provider_section, content: different_provider_exercise) }

        let(:course2) { create(:course, course_code: 'the-second-course', title: 'The Second Course', context_id: 'coursecontext2') }
        let(:course2_provider) { create(:lti_provider, :pseudonymized, course_id: course2.id) }
        let(:different_course_different_provider_exercise) { create(:lti_exercise, provider: course2_provider) }
        let(:different_course_different_provider_section) { create(:section, course: course2) }
        let(:different_course_different_provider_item) { create(:item, section: different_course_different_provider_section, content: different_course_different_provider_exercise) }

        before do
          same_provider_item
          different_course_same_provider_item
          different_provider_item
          different_course_different_provider_item
        end

        it 'differs for different users' do
          expect(
            exercise.launch_for(user).data_hash['user_id']
          ).not_to eq(
            exercise.launch_for(user2).data_hash['user_id']
          )
        end

        it 'is the same across different exercises within a course for the same provider' do
          expect(
            exercise.launch_for(user).data_hash['user_id']
          ).to eq(
            same_provider_exercise.launch_for(user).data_hash['user_id']
          )
        end

        it 'differs across different exercises within a course for different providers' do
          expect(
            exercise.launch_for(user).data_hash['user_id']
          ).not_to eq(
            different_provider_exercise.launch_for(user).data_hash['user_id']
          )
        end

        it 'is the same across different courses for global providers' do
          expect(
            exercise.launch_for(user).data_hash['user_id']
          ).to eq(
            different_course_same_provider_exercise.launch_for(user).data_hash['user_id']
          )
        end

        it 'differs across different courses for course providers' do
          expect(
            exercise.launch_for(user).data_hash['user_id']
          ).not_to eq(
            different_course_different_provider_exercise.launch_for(user).data_hash['user_id']
          )
        end
      end
    end
  end

  it 'includes LTI Launch fields' do
    expect(launch.data_hash).to include(
      'lti_message_type' => 'basic-lti-launch-request',
      'lti_version' => 'LTI-1p0'
    )
  end

  it 'includes OAuth fields' do
    expect(launch.data_hash).to match hash_including(
      'oauth_consumer_key' => 'teambuilder-app',
      'oauth_signature_method' => String,
      'oauth_timestamp' => String,
      'oauth_nonce' => String,
      'oauth_version' => '1.0',
      'oauth_signature' => String
    )
  end

  it 'includes a return URL' do
    expect(launch.data_hash).to match hash_including(
      'launch_presentation_return_url' => %r{https://xikolo\.de/courses/the-course/items/[A-Za-z0-9]{14,22}/tool_return}
    )
  end

  it 'launches as student by default' do
    expect(launch.data_hash['roles']).to eq 'Learner'
  end

  context 'when the user is allowed to instruct on LTI tools' do
    let(:permissions) { ['lti.tool.instruct'] }

    it 'launches as instructor' do
      expect(launch.data_hash['roles']).to eq 'Instructor'
    end
  end

  context 'when the user is allowed to administrate LTI tools' do
    let(:permissions) { ['lti.tool.administrate'] }

    it 'launches as administrator' do
      expect(launch.data_hash['roles']).to eq 'Administrator'
    end
  end

  context 'when an exercise has its own custom parameters' do
    before { exercise.update(custom_fields: 'foo=bar&baz=bam&url=http%3A%2F%2Fwww.example.com%2F%3Ffoo%3D1%26bar%3D2') }

    it "includes the exercise's custom parameters" do
      expect(launch.data_hash).to match hash_including(
        'custom_foo' => 'bar',
        'custom_baz' => 'bam',
        'custom_url' => 'http://www.example.com/?foo=1&bar=2'
      )
    end
  end

  context 'when the provider also has its own custom parameters' do
    before do
      provider.update(custom_fields: 'prov1=val')
      exercise.update(custom_fields: 'foo=bar&baz=bam')
    end

    it "includes the provider's and the exercise's custom parameters" do
      expect(launch.data_hash).to match hash_including(
        'custom_prov1' => 'val',
        'custom_foo' => 'bar',
        'custom_baz' => 'bam'
      )
    end
  end

  context 'when the item has a future deadline' do
    let(:submission_deadline) { 2.days.from_now }

    it 'marks the exercise as active' do
      expect(launch.data_hash['custom_state']).to eq 'active'
    end

    it 'includes an outcome URL' do
      expect(launch.data_hash).to match hash_including(
        'lis_outcome_service_url' => %r{https://xikolo\.de/courses/the-course/items/[A-Za-z0-9]{14,22}/tool_grading}
      )
    end
  end

  context 'when the item has a passed deadline' do
    let(:submission_deadline) { 1.week.ago }

    it 'marks the exercise as expired' do
      expect(launch.data_hash['custom_state']).to eq 'expired'
    end

    it 'does not include an outcome URL' do
      expect(launch.data_hash.keys).not_to include 'lis_outcome_service_url'
    end

    context 'with course reactivation' do
      before { create(:enrollment, user_id:, course:, forced_submission_date: 1.week.from_now) }

      it 'marks the exercise as active' do
        expect(launch.data_hash['custom_state']).to eq 'active'
      end

      it 'includes an outcome URL' do
        expect(launch.data_hash).to match hash_including(
          'lis_outcome_service_url' => %r{https://xikolo\.de/courses/the-course/items/[A-Za-z0-9]{14,22}/tool_grading}
        )
      end
    end
  end

  describe 'gradebook maintenance' do
    let(:matching_gradebooks) { exercise.gradebooks.where(user_id:) }

    context 'when no gradebook exists' do
      before do
        matching_gradebooks.delete_all
      end

      it 'creates one' do
        expect { launch.data_hash }.to change(matching_gradebooks, :count).from(0).to(1)
      end

      it "includes the new gradebook's ID" do
        expect(launch.data_hash['lis_result_sourcedid']).to eq matching_gradebooks.first.id
      end

      context 'when the exercise does not accept submissions anymore' do
        let(:exercise) { create(:lti_exercise, :locked, provider:) }

        it 'does not include any gradebook ID' do
          expect(launch.data_hash).not_to include 'lis_result_sourcedid'
        end
      end
    end

    context 'when a gradebook already exists' do
      let!(:gradebook) { create(:lti_gradebook, exercise:, user_id:) }

      it 'does not create a new gradebook' do
        expect { launch.data_hash }.not_to change(matching_gradebooks, :count)
      end

      it "includes the existing gradebook's ID" do
        expect(launch.data_hash['lis_result_sourcedid']).to eq gradebook.id
      end
    end
  end

  describe '#form_target' do
    subject { launch.form_target }

    before do
      # HACK: Ensure we wait for all requests triggered by the ToolLaunch
      # initializer, to prevent flaky time-based failures.
      launch.data_hash
    end

    context 'when the provider is configured to open in a new pop-up' do
      let(:provider) { create(:lti_provider, presentation_mode: 'pop-up', course_id:) }

      it { is_expected.to eq '_blank' }
    end

    context 'when the provider is configured to open in the current window' do
      let(:provider) { create(:lti_provider, presentation_mode: 'window', course_id:) }

      it { is_expected.to eq '_self' }
    end
  end

  ## Add before block that waits for all requests in initializer
  describe '#presentation_mode' do
    subject { launch.presentation_mode }

    before do
      # HACK: Ensure we wait for all requests triggered by the ToolLaunch
      # initializer, to prevent flaky time-based failures.
      launch.data_hash
    end

    context 'when the provider is configured to open in a new pop-up' do
      let(:provider) { create(:lti_provider, presentation_mode: 'pop-up', course_id:) }

      it { is_expected.to eq 'pop-up' }
    end

    context 'when the provider is configured to open in the current window' do
      let(:provider) { create(:lti_provider, presentation_mode: 'window', course_id:) }

      it { is_expected.to eq 'window' }
    end

    context 'when the provider is configured to open in an iframe' do
      let(:provider) { create(:lti_provider, presentation_mode: 'frame', course_id:) }

      it { is_expected.to eq 'frame' }
    end
  end
end

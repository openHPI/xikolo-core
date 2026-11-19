# frozen_string_literal: true

require 'spec_helper'

describe CourseService::LtiExercise::Clone do
  subject(:new_lti_exercise) do
    described_class.call(lti_exercise, new_course_id)
  end

  let!(:lti_exercise) { create(:lti_exercise, provider: lti_provider) }
  let(:lti_provider) { create(:lti_provider) }
  let(:new_course_id) { generate(:course_id) }

  context 'with a referenced LTI provider' do
    it 'clones the LTI exercise' do
      expect(new_lti_exercise.id).not_to eq lti_exercise.id
      expect(new_lti_exercise.provider.id).not_to eq lti_exercise.provider.id
    end

    it 'clones its provider' do
      expect { new_lti_exercise }.to change(Lti::Exercise, :count).from(1).to(2)
      new_provider = Lti::Provider.find(new_lti_exercise.provider.id)
      expect(new_provider.course_id).to eq new_course_id
      expect(new_provider.attributes.except('id', 'course_id', 'created_at', 'updated_at')).to eq \
        lti_provider.attributes.except('id', 'course_id', 'created_at', 'updated_at')
    end
  end

  context 'with an already cloned LTI provider' do
    it 'reuses the provider' do
      new_provider = create(:lti_provider, name: lti_exercise.provider.name, course_id: new_course_id)
      expect { new_lti_exercise }.not_to change(Lti::Provider, :count).from(2)
      expect(new_lti_exercise.provider.id).to eq new_provider.id
    end
  end

  context 'with a global LTI provider' do
    let(:lti_provider) { create(:lti_provider, :global) }

    it 'reuses the global CourseService::LTI provider' do
      expect { new_lti_exercise }.not_to change(Lti::Provider, :count).from(1)
      expect(new_lti_exercise.provider.id).to eq lti_provider.id
    end
  end

  context 'with LTI instructions' do
    let(:lti_exercise) do
      create(:lti_exercise,
        provider: lti_provider,
        instructions: "Test\ns3://xikolo-public/exercises/asfd/hans.jpg")
    end
    let!(:copy_instructions) do
      stub_request(:put, %r{#{test_s3_host}/xikolo-public/exercises/[a-zA-Z0-9]+/hans.jpg})
        .and_return(status: 200, body: '<xml></xml>')
    end

    it 'copies its instructions successfully, creating (valid) new instructions' do
      new_lti_exercise
      expect(copy_instructions).to have_been_requested
      expect(new_lti_exercise.instructions.to_s).to start_with("Test\ns3://xikolo-public/exercises/")
    end

    it 'does not refer to the original instructions' do
      expect(new_lti_exercise.instructions).not_to eq lti_exercise.instructions
    end
  end
end

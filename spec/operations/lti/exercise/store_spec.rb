# frozen_string_literal: true

require 'spec_helper'

describe Lti::Exercise::Store, type: :operation do
  subject(:store_exercise) { described_class.call(exercise, params) }

  let!(:exercise) { create(:lti_exercise, initial_params) }
  let(:initial_params) { {id: '4290e188-6063-4721-95ea-c2b35bc95e86'} }

  context 'with changed attributes' do
    let(:params) { {title: 'New Title'} }

    it 'updates the database' do
      expect { store_exercise; exercise.reload }.to change(exercise, :title).to('New Title')
    end
  end

  context 'deleting the instructions field' do
    let(:params) { {title: 'New Title', instructions: nil} }
    let(:initial_params) { super().merge(instructions: 'A few markup instructions') }

    it 'updates all fields correctly' do
      expect { store_exercise; exercise.reload }.to \
        change(exercise, :title).to('New Title')
        .and change(exercise, :instructions).to(nil)
    end
  end

  context 'for richtext with valid uploads' do
    let(:params) { {instructions: text} }

    let(:text) { 'upload://b5f99337-224f-40f5-aa82-44ee8b272579/foo.jpg' }

    it 'stores the upload and updates the exercise' do
      stub_request(
        :head,
        'https://s3.xikolo.de/xikolo-uploads/' \
        'uploads/b5f99337-224f-40f5-aa82-44ee8b272579/foo.jpg'
      ).and_return(
        status: 200,
        headers: {
          'X-Amz-Meta-Xikolo-Purpose' => 'lti_exercise_instructions',
          'X-Amz-Meta-Xikolo-State' => 'accepted',
        }
      )
      store_regex = %r{https://s3.xikolo.de/xikolo-public
                       /ltiexercises/21BHFCPYoUuzziqRhNss7k/foo.jpg}x
      stub_request(:head, store_regex).and_return(status: 404)
      stub_request(:put, store_regex).and_return(status: 200, body: '<xml></xml>')
      expect { store_exercise }.to change { exercise.reload.instructions.to_s }
      expect(exercise.instructions.to_s).to include 's3://xikolo-public/ltiexercise'
    end

    it 'rejects invalid upload and does not update the exercise' do
      stub_request(
        :head,
        'https://s3.xikolo.de/xikolo-uploads/' \
        'uploads/b5f99337-224f-40f5-aa82-44ee8b272579/foo.jpg'
      ).and_return(
        status: 200,
        headers: {
          'X-Amz-Meta-Xikolo-Purpose' => 'lti_exercise_instructions',
          'X-Amz-Meta-Xikolo-State' => 'rejected',
        }
      )

      expect(store_exercise.errors[:instructions]).to eq ['Your file upload has been rejected due to policy violations.']
    end

    it 'rejects upload on storage errors' do
      stub_request(
        :head,
        'https://s3.xikolo.de/xikolo-uploads/' \
        'uploads/b5f99337-224f-40f5-aa82-44ee8b272579/foo.jpg'
      ).and_return(
        status: 200,
        headers: {
          'X-Amz-Meta-Xikolo-Purpose' => 'lti_exercise_instructions',
          'X-Amz-Meta-Xikolo-State' => 'accepted',
        }
      )
      store_regex = %r{https://s3.xikolo.de/xikolo-public
                       /ltiexercises/21BHFCPYoUuzziqRhNss7k/foo.jpg}x
      stub_request(:head, store_regex).and_return(status: 404)
      stub_request(:put, store_regex).and_return(status: 503)

      expect(store_exercise.errors[:instructions]).to eq ['Your file upload could not be stored.']
    end
  end
end

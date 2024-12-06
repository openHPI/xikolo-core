# frozen_string_literal: true

require 'spec_helper'
require 'support/email'

describe PeerAssessmentConsumer, type: :consumer do
  subject(:consumer) { PeerAssessmentConsumer.new }

  let(:conflict_id) { SecureRandom.uuid }
  let(:reporter_id) { generate(:user_id) }
  let(:accused_id) { generate(:user_id) }
  let(:teacher_id) { generate(:user_id) }
  let(:course_id) { SecureRandom.uuid }
  let(:peer_assessment_id) { SecureRandom.uuid }
  let(:conflict_reason) { 'plagiarism' }
  let(:assessment_title) { 'Test Assessment' }
  let(:payload) { {id: conflict_id} }

  let(:conflict_stub_response) do
    Stub.json({
      id: conflict_id,
      reporter: reporter_id,
      accused: accused_id,
      reason: conflict_reason,
      peer_assessment_id:,
      conflict_subject_type: 'Submission',
    })
  end

  before do
    Stub.service(
      :peerassessment,
      peer_assessment_url: 'http://localhost:5400/peer_assessments/{id}',
      conflict_url: 'http://localhost:5400/conflicts/{id}'
    )
    Stub.request(
      :peerassessment, :get, "/conflicts/#{conflict_id}"
    ).to_return conflict_stub_response

    Stub.request(
      :course, :get, "/courses/#{course_id}"
    ).to_return Stub.json({
      id: course_id,
      lang: 'en',
    })

    Stub.request(
      :account, :get, "/users/#{reporter_id}"
    ).to_return Stub.json({
      id: reporter_id,
      name: 'John Smith',
      email: 'john.smith@example.org',
    })
    Stub.request(
      :account, :get, "/users/#{accused_id}"
    ).to_return Stub.json({
      id: accused_id,
      name: 'Kevin Cool',
      email: 'kevin.cool@example.org',
    })
    Stub.request(
      :account, :get, "/users/#{teacher_id}"
    ).to_return Stub.json({
      id: teacher_id,
      name: 'Adam Administrator',
      email: 'admin@example.com',
    })

    Stub.request(
      :peerassessment, :get, "/peer_assessments/#{peer_assessment_id}"
    ).to_return Stub.json({
      id: peer_assessment_id,
      title: assessment_title,
      course_id:,
    })

    Msgr.client.start

    # Tests mock several calls to Msgr.publish. Other calls (e.g. the actual test subject) should still work.
    allow(Msgr).to receive(:publish).with(
      anything,
      hash_not_including(to: 'xikolo.notification.notify')
    ).and_call_original
  end

  describe '#new_conflict' do
    it 'sends two mails (to reporter and accused student) for new general conflicts' do
      expect(Msgr).to receive(:publish).with(
        hash_including(receiver_id: reporter_id),
        hash_including(to: 'xikolo.notification.notify')
      )
      expect(Msgr).to receive(:publish).with(
        hash_including(receiver_id: accused_id),
        hash_including(to: 'xikolo.notification.notify')
      )

      Msgr.publish(payload, to: 'xikolo.peer_assessment.conflict.create')
      Msgr::TestPool.run count: 1
    end

    context 'without conflict' do
      let(:conflict_stub_response) { {status: 404} }

      it 'does not send any mails' do
        expect(Msgr).not_to receive(:publish).with(
          anything,
          hash_including(to: 'xikolo.notification.notify')
        )

        Msgr.publish(payload, to: 'xikolo.peer_assessment.conflict.create')
        Msgr::TestPool.run count: 1
      end
    end
  end

  describe '#conflict_resolved' do
    it 'sends two mails (to reporter and accused student) for resolved general conflicts' do
      expect(Msgr).to receive(:publish).with(
        hash_including(receiver_id: reporter_id),
        hash_including(to: 'xikolo.notification.notify')
      )
      expect(Msgr).to receive(:publish).with(
        hash_including(receiver_id: accused_id),
        hash_including(to: 'xikolo.notification.notify')
      )

      Msgr.publish(payload, to: 'xikolo.peer_assessment.conflict.resolved')
      Msgr::TestPool.run count: 1
    end

    context 'with no reviews' do
      let(:conflict_reason) { 'no_reviews' }

      it 'sends two notifications (to reporter and accused student)' do
        expect(Msgr).to receive(:publish).with(
          hash_including(receiver_id: reporter_id),
          hash_including(to: 'xikolo.notification.notify')
        )
        expect(Msgr).to receive(:publish).with(
          hash_including(receiver_id: accused_id),
          hash_including(to: 'xikolo.notification.notify')
        )

        Msgr.publish(payload, to: 'xikolo.peer_assessment.conflict.resolved')
        Msgr::TestPool.run count: 1
      end
    end
  end

  describe '#regrading' do
    let(:conflict_reason) { 'grading_conflict' }

    describe '#new_regrading' do
      it 'sends one mail to reporter for new regrading conflicts' do
        expect(Msgr).to receive(:publish).with(
          hash_including(receiver_id: reporter_id),
          hash_including(to: 'xikolo.notification.notify')
        )

        Msgr.publish(payload, to: 'xikolo.peer_assessment.conflict.create')
        Msgr::TestPool.run count: 1
      end
    end

    describe '#resolved_regrading' do
      it 'sends one mail to reporter for resolved regrading conflicts' do
        expect(Msgr).to receive(:publish).with(
          hash_including(receiver_id: reporter_id),
          hash_including(to: 'xikolo.notification.notify')
        )

        Msgr.publish(payload, to: 'xikolo.peer_assessment.conflict.create')
        Msgr::TestPool.run count: 1
      end
    end
  end
end

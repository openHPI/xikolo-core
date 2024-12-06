# frozen_string_literal: true

require 'spec_helper'

describe PeerAssessment::ConflictsController, type: :controller do
  let(:json) { response.parsed_body }

  let(:assessment_id) { SecureRandom.uuid }
  let(:step_id) { SecureRandom.uuid }
  let(:submission_id) { SecureRandom.uuid }
  let(:course_id) { SecureRandom.uuid }
  let(:user_id) { SecureRandom.uuid }
  let(:file_owner) { user_id }
  let(:item_id) { UUID(SecureRandom.uuid) }
  let(:file_id) { SecureRandom.uuid }
  let(:attachments) { [] }
  let(:allowed_attachments) { 1 }
  let(:request_context_id) { course_context_id }
  let(:permissions) { ['course.content.access', 'course.content.access.available', 'peerassessment.conflicts.manage'] }

  before do
    ### Begin common stubs ###
    Stub.service(
      :course,
      course_url: '/courses/{id}',
      enrollments_url: '/enrollments',
      item_url: '/items/{id}'
    )

    Stub.service(
      :peerassessment,
      steps_url: '/steps',
      submission_url: '/submission/{id}',
      submissions_url: '/submissions',
      peer_assessment_url: '/peer_assessment/{id}',
      grade_url: '/grades/{id]',
      grades_url: '/grades',
      conflict_url: '/conflicts/{id}',
      conflicts_url: '/conflicts',
      notes_url: '/notes',
      assignment_submissions_url: '/assignment_submissions',
      peer_gradings_url: '/peer_gradings',
      reviews_url: '/reviews',
      self_assessments_url: '/self_assessments'
    )

    Stub.request(
      :peerassessment, :get, "/peer_assessment/#{assessment_id}"
    ).to_return Stub.json({
      id: assessment_id,
      course_id:,
      item_id:,
      attachments: [],
      allowed_attachments:,
      is_team_assessment: false,
    })

    Stub.request(
      :peerassessment, :get, '/steps',
      query: {peer_assessment_id: assessment_id}
    ).to_return Stub.json([])

    Stub.request(
      :peerassessment, :get, "/peer_assessments/#{assessment_id}"
    ).to_return Stub.json({
      id: assessment_id,
      course_id:,
      item_id:,
      attachments: [],
      allowed_attachments:,
    })

    Stub.request(
      :course, :get, "/courses/#{course_id}"
    ).to_return Stub.json({
      id: course_id,
      context_id: course_context_id,
      status: 'active',
    })

    Stub.request(
      :course, :get, "/items/#{item_id}"
    ).to_return Stub.json({
      id: item_id,
    })

    Stub.request(
      :course, :get, '/enrollments',
      query: {user_id:, course_id:}
    ).to_return Stub.json([
      {user_id:, course_id:},
    ])

    Stub.service(
      :account,
      session_url: '/sessions/{id}',
      user_url: '/users/{id}'
    )

    Stub.request(
      :account, :get, "/users/#{user_id}"
    ).to_return Stub.json({
      id: user_id,
    })

    stub_user id: user_id, permissions:
    ### END Common stubs ###
  end

  describe '#index' do
    subject(:action) { get :index, params: }

    before do
      Stub.request(
        :peerassessment, :get, '/conflicts',
        query: {peer_assessment_id: assessment_id, per_page: 30, page: 1, open: '', reason: ''}
      ).to_return Stub.json([])
    end

    let(:params) { {peer_assessment_id: assessment_id} }

    it 'answers with a 200' do
      expect(action.status).to eq 200
    end
  end

  describe '#show' do
    subject(:action) { get :show, params: }

    let(:params) { {peer_assessment_id: assessment_id, id: conflict_id} }
    let(:accused_id) { SecureRandom.uuid }
    let(:subject_id) { SecureRandom.uuid }
    let(:conflict_id) { SecureRandom.uuid }
    let(:review_id) { SecureRandom.uuid }

    before do
      Stub.request(
        :peerassessment, :get, "/conflicts/#{UUID4.try_convert(conflict_id)}"
      ).to_return Stub.json({
        id: conflict_id,
        conflict_subject_type: 'Submission',
        accused: accused_id,
        reporter: user_id,
        created_at: DateTime.now,
        conflict_subject_id: subject_id,
      })
      Stub.request(
        :account, :get, "/users/#{accused_id}"
      ).to_return Stub.json({
        id: accused_id,
      })
      Stub.request(
        :peerassessment, :get, "/submission/#{subject_id}"
      ).to_return Stub.json({
        id: subject_id,
        attachments:,
        user_id: accused_id,
      })
      Stub.request(
        :peerassessment, :get, '/submissions',
        query: {user_id:, peer_assessment_id: assessment_id}
      ).to_return Stub.json([
        {id: submission_id, attachments:, user_id:},
      ])
      Stub.request(
        :peerassessment, :get, '/submissions',
        query: {user_id: accused_id, peer_assessment_id: assessment_id}
      ).to_return Stub.json([
        {id: subject_id, attachments:, user_id: accused_id},
      ])
      Stub.request(
        :peerassessment, :get, '/grades',
        query: {peer_assessment_id: assessment_id, user_id:}
      ).to_return Stub.json(
        {}
      )
      Stub.request(
        :peerassessment, :get, '/grades',
        query: {peer_assessment_id: assessment_id, user_id: accused_id}
      ).to_return Stub.json(
        {}
      )
      Stub.request(
        :peerassessment, :get, '/notes',
        query: {subject_id: conflict_id}
      ).to_return Stub.json(
        {}
      )
      Stub.request(
        :peerassessment, :get, '/assignment_submissions',
        query: {peer_assessment_id: assessment_id}
      ).to_return Stub.json(
        {}
      )
      Stub.request(
        :peerassessment, :get, '/peer_gradings',
        query: {peer_assessment_id: assessment_id}
      ).to_return Stub.json(
        {}
      )
      Stub.request(
        :peerassessment, :get, '/self_assessments',
        query: {peer_assessment_id: assessment_id}
      ).to_return Stub.json(
        {}
      )
      Stub.request(
        :peerassessment, :get, '/reviews',
        query: {user_id: accused_id, step_id: 'nonsense', peer_assessment_id: assessment_id, submitted: true}
      ).to_return Stub.json({
        id: review_id,
        count: 1,
      })
      Stub.request(
        :peerassessment, :get, '/reviews',
        query: {user_id: accused_id, step_id: 'nonsense', peer_assessment_id: assessment_id}
      ).to_return Stub.json({
        id: review_id,
        count: 1,
      })
    end

    context 'Submission conflict' do
      it 'answers with a 200' do
        expect(action.status).to eq 200
      end
    end
  end

  describe '#reconcile' do
    subject(:action) { get :reconcile, params: }

    let(:params) { {peer_assessment_id: assessment_id, id: conflict_id} }
    let(:accused_id) { SecureRandom.uuid }
    let(:subject_id) { SecureRandom.uuid }
    let(:conflict_id) { SecureRandom.uuid }
    let(:review_id) { SecureRandom.uuid }

    before do
      Stub.request(
        :peerassessment, :get, "/conflicts/#{UUID4.try_convert(conflict_id)}"
      ).to_return Stub.json({
        id: conflict_id,
        conflict_subject_type: 'Submission',
        accused: accused_id,
        reporter: user_id,
        created_at: DateTime.now,
        conflict_subject_id: subject_id,
      })
      Stub.request(
        :peerassessment, :put, "/conflicts/#{UUID4.try_convert(conflict_id)}",
        body: {open: false}
      ).to_return Stub.json({
        response: {code: 204},
      })
      Stub.request(
        :account, :get, "/users/#{accused_id}"
      ).to_return Stub.json({
        id: accused_id,
      })
      Stub.request(
        :peerassessment, :get, '/grades',
        query: {peer_assessment_id: assessment_id, user_id:}
      ).to_return Stub.json(
        {}
      )
      Stub.request(
        :peerassessment, :get, '/grades',
        query: {peer_assessment_id: assessment_id, user_id: accused_id}
      ).to_return Stub.json(
        {}
      )
    end

    context 'Submission conflict' do
      context 'without change of grade' do
        it 'answers with a 200' do
          expect(action.status).to redirect_to peer_assessment_conflicts_path
        end
      end
    end
  end
end

# frozen_string_literal: true

require 'spec_helper'

describe 'Course: PeerAssessments: Index', type: :request do
  subject(:action) do
    get "/courses/#{course.course_code}/peer_assessments", headers:
  end

  let(:headers) { {} }
  let(:course) { create(:course, course_code: 'the-course') }
  let(:course_resource) do
    build(:'course:course', id: course.id, course_code: course.course_code)
  end
  let(:page) { Capybara.string(response.body) }

  before do
    stub_user_request permissions:

    Stub.service(:course, build(:'course:root'))
    Stub.request(:course, :get, '/courses/the-course')
      .to_return Stub.json(course_resource)
  end

  context 'with permissions' do
    let(:permissions) { %w[peerassessment.peerassessment.index course.content.access course.content.edit] }
    let(:headers) { super().merge('Authorization' => "Xikolo-Session session_id=#{stub_session_id}") }
    let(:user_id) { generate(:user_id) }
    let(:section) { create(:section, course_id: course.id) }

    before { stub_user_request(id: user_id, permissions:) }

    context 'with more than 50 peer assessments' do
      let(:peer_assessments) do
        # Add 51 valid peer assessments with corresponding items.
        (2..52).map do |i|
          item = create(:item, section:, title: "PeerAssessment n.#{i}")
          build(:'peerassessment:peerassessment',
            title: "PeerAssessment n.#{i}",
            course_id: course.id,
            item_id: item.id)
        end.unshift(
          # Add another peer assessment with missing item, i.e. deleted item.
          build(:'peerassessment:peerassessment',
            title: 'PeerAssessment n.1',
            course_id: course.id,
            item_id: generate(:item_id))
        )
      end
      let(:first_page) { peer_assessments[0..49] }
      let(:second_page) { peer_assessments[50..51] }

      before do
        Stub.service(:peerassessment,
          build(:'peerassessment:root').merge(
            'statistics_url' => '/statistics',
            'steps_url' => '/steps',
            'submissions_url' => '/submissions'
          ))

        # Pagination stubs
        Stub.request(
          :peerassessment, :get, '/peer_assessments',
          query: {course_id: course.id}
        ).to_return Stub.json(
          first_page,
          links: {next: "/peer_assessments?course_id=#{course.id}&page=2"},
          headers: {'X-Total-Pages' => 2, 'X-Current-Page' => 1}
        )
        Stub.request(
          :peerassessment, :get, '/peer_assessments',
          query: {course_id: course.id, page: 2}
        ).to_return Stub.json(
          second_page,
          links: {prev: "/peer_assessments?course_id=#{course.id}"},
          headers: {'X-Total-Pages' => 2, 'X-Current-Page' => 2}
        )

        # Stubs for retrieving submissions and statistics are run for each
        # peer assessment individually.
        peer_assessments[1..51].each do |peer_assessment|
          Stub.request(
            :peerassessment, :get, '/statistics',
            query: {peer_assessment_id: peer_assessment['id'], concern: 'assessment_statistic'}
          ).to_return Stub.json(build(:'peerassessment:statistic'))
          Stub.request(
            :peerassessment, :get, '/steps',
            query: {peer_assessment_id: peer_assessment['id']}
          ).to_return Stub.json([])
          Stub.request(
            :peerassessment, :get, '/submissions',
            query: {user_id:, peer_assessment_id: peer_assessment['id']}
          ).to_return Stub.json([])
        end

        pa_0 = peer_assessments[0]
        Stub.request(
          :peerassessment, :get, '/statistics',
          query: {peer_assessment_id: pa_0['id'], concern: 'assessment_statistic'}
        ).to_return Stub.json({})
        Stub.request(
          :peerassessment, :get, '/steps',
          query: {peer_assessment_id: pa_0['id']}
        ).to_return Stub.json([])
        Stub.request(
          :peerassessment, :get, '/submissions',
          query: {user_id:, peer_assessment_id: pa_0['id']}
        ).to_return Stub.json([])
      end

      it 'all peer assessments are displayed' do
        expect(peer_assessments.size).to eq 52
        action
        displayed_peer_assessments = page.find_all('.row[id="the-course"] h4')
        expect(displayed_peer_assessments.size).to eq 51
        expect(displayed_peer_assessments.map(&:text).sort!).to eq peer_assessments[1..51].pluck('title').sort!
      end
    end
  end
end

# frozen_string_literal: true

require 'spec_helper'

describe 'Course: Update', type: :request do
  before do
    create(:'course_service/cluster', id: 'category')
    create(:'course_service/cluster', id: 'topic')

    Stub.service(:account, build(:'account:root'))
  end

  let(:api) { Restify.new(:test).get.value! }
  let!(:course) { create(:'course_service/course', initial_params) }
  let(:initial_params) { {classifiers: {category: %w[databases pro-track]}} }
  let(:classifiers) do
    {
      category: ['Internet Technology 2', 'Beginner', 'Cat3', 'Cat4'],
    }
  end

  let(:action) do
    api.rel(:course).patch({
      title: 'new course title',
      classifiers:,
      proctored: true,
      invite_only: true,
    }, params: {id: course.id}).value!
  end
  let(:grant_visitor_group) { 'all' }
  let!(:grant_visitor_stub) do
    Stub.request(
      :account, :post, '/grants',
      body: {
        group: grant_visitor_group,
        context: course.context_id,
        role: 'course.visitor',
      }
    )
  end
  let(:existing_grants) { [] }
  let!(:list_visitor_stub) do
    Stub.request(
      :account, :get, '/grants'
    ).with(query: {
      context: course.context_id,
      role: 'course.visitor',
    }).and_return Stub.json(existing_grants)
  end

  context 'course' do
    subject { course.reload }

    before { action }

    its(:title) { is_expected.to eq 'new course title' }
    its(:classifiers) { is_expected.to have(4).items }
    its(:proctored) { is_expected.to be true }
    its(:invite_only) { is_expected.to be true }
  end

  context 'with multiple classifier clusters' do
    subject(:course_classifiers) { action; course.reload.classifiers }

    let(:classifiers) do
      {
        category: %w[a b],
        topic: ['c'],
      }
    end

    it 'adds new classifiers and removes old classifiers' do
      expect { action }.to change { course.reload.classifiers.size }.from(2).to(3)
    end

    it 'has correct classifiers' do
      expect(course_classifiers.map(&:cluster_id).uniq).to match_array %w[category topic]
      expect(course_classifiers.select {|c| c.cluster_id == 'category' }.pluck(:title, :position)).to contain_exactly(['a', 1], ['b', 2])
      expect(course_classifiers.select {|c| c.cluster_id == 'topic' }.pluck(:title, :position)).to contain_exactly(['c', 1])
    end
  end

  context 'with an empty list of classifiers' do
    let(:classifiers) { {} }

    it 'removes all classifiers' do
      expect { action }.to change { course.reload.classifiers.size }.from(2).to(0)
    end
  end

  context 'for richtext with valid uploads' do
    let!(:course) { create(:'course_service/course', initial_params) }
    let(:initial_params) { {id: '4290e188-6063-4721-95ea-c2b35bc95e86'} }
    let(:action) do
      api.rel(:course).patch({description: text}, params: {id: course.id}).value!
    end
    let(:text) { 'upload://b5f99337-224f-40f5-aa82-44ee8b272579/company1.jpg' }

    it 'stores the upload and update course' do
      stub_request(
        :head,
        'https://s3.xikolo.de/xikolo-uploads/' \
        'uploads/b5f99337-224f-40f5-aa82-44ee8b272579/company1.jpg'
      ).and_return(
        status: 200,
        headers: {
          'X-Amz-Meta-Xikolo-Purpose' => 'course_course_description',
          'X-Amz-Meta-Xikolo-State' => 'accepted',
        }
      )
      store_regex = %r{https://s3.xikolo.de/xikolo-public
                       /courses/21BHFCPYoUuzziqRhNss7k
                       /rtfiles/[0-9a-zA-Z]+/company1.jpg}x
      stub_request(:head, store_regex).and_return(status: 404)
      stub_request(:put, store_regex).and_return(status: 200, body: '<xml></xml>')
      expect { action; course.reload }.to change(course, :description)
        .from('Some course ...')
      expect(course.description).to include 's3://xikolo-public/course'
    end

    it 'rejects invalid upload and does not updates course' do
      stub_request(
        :head,
        'https://s3.xikolo.de/xikolo-uploads/' \
        'uploads/b5f99337-224f-40f5-aa82-44ee8b272579/company1.jpg'
      ).and_return(
        status: 200,
        headers: {
          'X-Amz-Meta-Xikolo-Purpose' => 'course_course_description',
          'X-Amz-Meta-Xikolo-State' => 'rejected',
        }
      )

      expect { action }.to raise_error(Restify::ClientError) do |error|
        expect(error.status).to eq :unprocessable_content
        expect(error.errors).to eq \
          'description' => ['rtfile_rejected']
      end
    end

    it 'rejects upload on storage errors' do
      stub_request(
        :head,
        'https://s3.xikolo.de/xikolo-uploads/' \
        'uploads/b5f99337-224f-40f5-aa82-44ee8b272579/company1.jpg'
      ).and_return(
        status: 200,
        headers: {
          'X-Amz-Meta-Xikolo-Purpose' => 'course_course_description',
          'X-Amz-Meta-Xikolo-State' => 'accepted',
        }
      )
      store_regex = %r{https://s3.xikolo.de/xikolo-public
                       /courses/21BHFCPYoUuzziqRhNss7k
                       /rtfiles/[0-9a-zA-Z]+/company1.jpg}x
      stub_request(:head, store_regex).and_return(status: 404)
      stub_request(:put, store_regex).and_return(status: 503)

      expect { action }.to raise_error(Restify::ClientError) do |error|
        expect(error.status).to eq :unprocessable_content
        expect(error.errors).to eq \
          'description' => ['rtfile_error']
      end
    end
  end

  context '(course visitor grants)' do
    let(:initial_params) { super().merge status: 'preparation' }

    context 'when not publishing the course' do
      it 'does not grant all users the permission to visit the course details page' do
        action
        expect(grant_visitor_stub).not_to have_been_requested
        expect(list_visitor_stub).to have_been_requested
      end

      context 'with existing grants' do
        let(:existing_grant_id) { SecureRandom.uuid }
        let(:existing_grants) do
          [{
            context: course.context_id,
            role_name: 'course.visitor',
            group: grant_visitor_group,
            self_url: "http://web.xikolo.tld/account_service/grants/#{existing_grant_id}",
          }]
        end
        let!(:delete_visitor_stub) do
          Stub.request(
            :account, :delete, "/grants/#{existing_grant_id}"
          ).and_return(status: 200)
        end

        it 'explicitly revokes all grants' do
          action
          expect(grant_visitor_stub).not_to have_been_requested
          expect(list_visitor_stub).to have_been_requested
          expect(delete_visitor_stub).to have_been_requested
        end
      end
    end

    context 'when publishing the course' do
      let(:data) do
        {
          status: 'active',
          start_date: 2.days.from_now,
          end_date: 10.days.from_now,
        }
      end
      let(:action) { api.rel(:course).patch(data, params: {id: course.id}).value! }
      let(:grant_id) { SecureRandom.uuid }
      let(:existing_grants) do
        [
          {
            context: course.context_id,
            role_name: 'course.visitor',
            group: grant_visitor_group,
            self_url: "http://web.xikolo.tld/account_service/grants/#{grant_id}",
          },
        ]
      end
      let!(:delete_visitor_stub) do
        Stub.request(
          :account, :delete, "/grants/#{grant_id}"
        ).and_return(status: 200)
      end

      it 'changes the course state to active' do
        expect { action }.to change { course.reload.status }.from('preparation').to('active')
      end

      it 'grants all users the permission to visit the course details page' do
        action
        expect(grant_visitor_stub).to have_been_requested
        expect(list_visitor_stub).to have_been_requested
        expect(delete_visitor_stub).not_to have_been_requested
      end

      context 'with already existing grant' do
        let(:existing_grant_id) { SecureRandom.uuid }
        let(:existing_grant) do
          {
            context: course.context_id,
            role_name: 'course.visitor',
            group: grant_visitor_group,
            self_url: "http://web.xikolo.tld/account_service/grants/#{existing_grant_id}",
          }
        end
        let!(:grant_visitor_stub) do
          Stub.request(
            :account, :post, '/grants',
            body: {
              group: grant_visitor_group,
              context: course.context_id,
              role: 'course.visitor',
            }
          ).and_return(Stub.json(existing_grant))
        end

        it 'keeps the existing grant' do
          action
          expect(delete_visitor_stub).not_to have_been_requested
          expect(grant_visitor_stub).to have_been_requested.once
        end
      end

      context 'with additional (obsolete) grant' do
        let(:additional_grant_id) { SecureRandom.uuid }
        let(:additional_grant) do
          {
            context: course.context_id,
            role_name: 'course.visitor',
            group: 'xikolo.other_group',
            self_url: "http://web.xikolo.tld/account_service/grants/#{additional_grant_id}",
          }
        end
        let(:existing_grants) { super() << additional_grant }
        let!(:delete_additional_grant_stub) do
          Stub.request(
            :account, :delete, "/grants/#{additional_grant_id}"
          ).and_return(status: 200)
        end

        it 'revokes the additional grant only' do
          action
          expect(delete_visitor_stub).not_to have_been_requested
          expect(delete_additional_grant_stub).to have_been_requested
        end
      end

      context 'with not successful course update' do
        let(:update_operation) { instance_double(Course::Update, update: false) }

        before do
          allow(Course::Update).to receive(:call).and_return update_operation
        end

        it 'does not revoke or grant course visitor permissions' do
          action
          expect(grant_visitor_stub).not_to have_been_requested
          expect(list_visitor_stub).not_to have_been_requested
          expect(delete_visitor_stub).not_to have_been_requested
        end
      end

      context 'with group restrictions' do
        let(:grant_visitor_group) { 'xikolo.affiliated' }
        let(:data) { super().merge(groups: [grant_visitor_group]) }

        it 'grants the permission to visit the course details page to the respective group' do
          action
          expect(grant_visitor_stub).to have_been_requested
          expect(list_visitor_stub).to have_been_requested
          expect(delete_visitor_stub).not_to have_been_requested
        end

        context 'with additional (obsolete) grant' do
          let(:additional_grant_id) { SecureRandom.uuid }
          let(:additional_grant) do
            {
              context: course.context_id,
              role_name: 'course.visitor',
              group: 'all',
              self_url: "http://web.xikolo.tld/account_service/grants/#{additional_grant_id}",
            }
          end
          let(:existing_grants) { super() << additional_grant }
          let!(:delete_additional_grant_stub) do
            Stub.request(
              :account, :delete, "/grants/#{additional_grant_id}"
            ).and_return(status: 200)
          end

          it 'revokes the additional grant only' do
            action
            expect(delete_visitor_stub).not_to have_been_requested
            expect(delete_additional_grant_stub).to have_been_requested
          end
        end
      end
    end
  end

  context 'with group restrictions' do
    subject(:patch) do
      api.rel(:course).patch({
        groups: ['group.b', 'group.c'],
      }, params: {id: course.id}).value!
    end

    let!(:course) { create(:'course_service/course', groups: ['group.a']) }

    it do
      expect { patch }
        .to change { course.reload.groups }
        .from(['group.a'])
        .to(['group.b', 'group.c'])
    end
  end
end

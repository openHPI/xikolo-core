# frozen_string_literal: true

require 'spec_helper'

describe Course::Create, type: :operation do
  subject(:response) { described_class.call(params) }

  let(:params) { {course_code: 'test_code', title: 'Test Course', description: 'Desc'} }
  let(:handler) { described_class.new params }
  let(:context_id) { generate(:context_id) }

  let(:course_visitor_group) { 'all' }

  let(:students_group) do
    {
      'description' => 'Students of course %s',
      'grants' => [],
    }
  end
  let(:course_groups) do
    {
      'students' => students_group,
    }
  end

  let(:context_stub) do
    Stub.request(
      :account, :post, '/contexts',
      body: {
        parent: 'root',
        reference_uri: "urn:x-xikolo:course:course:#{params[:course_code]}",
      }
    ).to_return Stub.json({id: context_id})
  end
  let(:students_group_stub) do
    Stub.request(
      :account, :post, '/groups',
      body: {
        name: "course.#{params[:course_code]}.students",
        description: "Students of course #{params[:course_code]}",
      }
    )
  end
  let(:course_visitor_stub) do
    Stub.request(
      :account, :post, '/grants',
      body: {
        group: course_visitor_group,
        context: context_id,
        role: 'course.visitor',
      }
    )
  end

  before do
    Xikolo.config.course_groups = course_groups
    Stub.service(
      :account,
      contexts_url: '/contexts',
      grants_url: '/grants',
      group_url: '/groups/{id}',
      groups_url: '/groups'
    )
    context_stub
    students_group_stub
    course_visitor_stub
  end

  it { is_expected.to be_valid }
  it { is_expected.not_to be_changed }
  its(:context_id) { is_expected.to eq context_id }
  its(:special_groups) { is_expected.to eq [] }

  context 'with additional course groups' do
    let(:course_groups) do
      {
        'students' => students_group,
        'teachers' => teachers_group,
      }
    end
    let(:teachers_group) do
      {
        'description' => 'Teachers of %s',
        'grants' => grants,
      }
    end
    let!(:teachers_group_stub) do
      Stub.request(
        :account, :post, '/groups',
        body: {
          name: "course.#{params[:course_code]}.teachers",
          description: "Teachers of #{params[:course_code]}",
        }
      ).to_return Stub.json({name: "course.#{params[:course_code]}.teachers"})
    end
    let(:grants) do
      [
        {'role' => 'account.teacher', 'context' => 'course'},
      ]
    end
    let!(:teachers_group_grant) do
      Stub.request(
        :account, :post, '/grants',
        body: {
          group: "course.#{params[:course_code]}.teachers",
          context: context_id,
          role: 'account.teacher',
        }
      )
    end

    it { is_expected.to be_valid }
    it { is_expected.not_to be_changed }
    its(:context_id) { is_expected.to eq context_id }
    its(:special_groups) { is_expected.to eq ['teachers'] }

    it 'calls all stubs' do
      response
      expect(context_stub).to have_been_requested
      expect(students_group_stub).to have_been_requested
      expect(teachers_group_stub).to have_been_requested
      expect(teachers_group_grant).to have_been_requested
    end

    it 'does not grant all users the permission to visit the course details page' do
      response
      expect(course_visitor_stub).not_to have_been_requested
    end

    context 'with global grant' do
      let(:grants) do
        [
          {'role' => 'account.teacher', 'context' => 'course'},
          {'role' => 'course.teacher.global', 'context' => 'root'},
        ]
      end
      let!(:teachers_group_grant2) do
        Stub.request(
          :account, :post, '/grants',
          body: {
            group: "course.#{params[:course_code]}.teachers",
            context: 'root',
            role: 'course.teacher.global',
          }
        )
      end

      it { is_expected.to be_valid }
      it { is_expected.not_to be_changed }
      its(:context_id) { is_expected.to eq context_id }
      its(:special_groups) { is_expected.to eq ['teachers'] }

      it 'calls student and teacher group stubs' do
        response
        expect(context_stub).to have_been_requested
        expect(students_group_stub).to have_been_requested
        expect(teachers_group_stub).to have_been_requested
        expect(teachers_group_grant).to have_been_requested
        expect(teachers_group_grant2).to have_been_requested
      end

      it 'does not grant all users the permission to visit the course details page' do
        response
        expect(course_visitor_stub).not_to have_been_requested
      end
    end
  end

  context 'without valid course parameters' do
    let(:params) { {course_code: 'test_code', title: 'Test Course'} }

    it { is_expected.not_to be_valid }
    it { is_expected.to be_changed }
  end

  context 'with http errors' do
    context 'on creating context' do
      let(:context_stub) do
        Stub.request(
          :account, :post, '/contexts',
          body: {
            parent: 'root',
            reference_uri: "urn:x-xikolo:course:course:#{params[:course_code]}",
          }
        ).to_return Stub.response(status: 503)
      end

      it 'does not change the number of courses' do
        expect { response }.not_to change(Course, :count).from(0)
      end

      it 'has an error attached' do
        expect(response.errors.size).to eq 1
        expect(response.errors[:base]).to eq ['error creating context']
      end
    end

    context 'on creating group' do
      let(:students_group_stub) do
        Stub.request(
          :account, :post, '/groups',
          body: {
            name: "course.#{params[:course_code]}.students",
            description: "Students of course #{params[:course_code]}",
          }
        ).to_return Stub.response(status: 422)
      end

      it 'does not change the number of courses' do
        expect { response }.not_to change(Course, :count).from(0)
      end

      it 'has an error attached' do
        expect(response.errors.size).to eq 1
        expect(response.errors[:base]).to eq ['error creating group']
      end
    end

    context 'with active course' do
      let(:params) { super().merge(status: 'active') }

      context 'on granting course.visitor role' do
        let(:course_visitor_stub) do
          Stub.request(
            :account, :post, '/grants',
            body: {
              group: course_visitor_group,
              context: context_id,
              role: 'course.visitor',
            }
          ).to_return Stub.response(status: 422)
        end

        it 'does not change the number of courses' do
          expect { response }.not_to change(Course, :count).from(0)
        end

        it 'has an error attached' do
          expect(response.errors.size).to eq 1
          expect(response.errors[:base]).to eq ['error granting role']
        end
      end
    end
  end

  context 'with active course' do
    let(:params) { super().merge(status: 'active') }

    it 'grants all users the permission to visit the course details page' do
      response
      expect(course_visitor_stub).to have_been_requested
    end

    context 'with group restrictions' do
      let(:course_visitor_group) { 'xikolo.affiliated' }
      let(:params) { super().merge(groups: [course_visitor_group]) }

      it 'grants the permission to visit the course details page to the respective group' do
        response
        expect(course_visitor_stub).to have_been_requested
      end
    end
  end
end

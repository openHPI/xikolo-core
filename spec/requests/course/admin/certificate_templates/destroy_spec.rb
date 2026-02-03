# frozen_string_literal: true

require 'spec_helper'

describe 'Course: Admin: Certificate Templates: Destroy', type: :request do
  subject(:delete_template) do
    delete "/courses/#{course.course_code}/certificate_templates/#{template.id}",
      headers:
  end

  let(:headers) { {'Authorization' => "Xikolo-Session session_id=#{stub_session_id}"} }
  let(:permissions) { %w[certificate.template.manage course.content.access] }
  let(:course) { create(:course, records_released: true) }
  let(:course_resource) { build(:'course:course', course_code: course.course_code) }
  let!(:template) do
    create(:certificate_template, :roa,
      course:,
      file_uri: 's3://xikolo-certificate/templates/abc.svg')
  end
  let!(:delete_stub) do
    stub_request(
      :delete,
      'https://s3.xikolo.de/xikolo-certificate/templates/abc.svg'
    ).to_return(status: 200)
  end

  before do
    stub_user_request(permissions:)

    Stub.request(:course, :get, "/courses/#{course.course_code}")
      .to_return Stub.json(course_resource)
  end

  it 'deletes the certificate template' do
    expect { delete_template }.to change(Certificate::Template, :count).from(1).to(0)
  end

  it 'removes the referenced S3 object' do
    delete_template
    expect(delete_stub).to have_been_requested
  end

  context 'with issued records' do
    before do
      user = create(:user)
      enrollment = create(:enrollment, course:, user_id: user.id)
      Stub.request(
        :course, :get, '/enrollments',
        query: {
          course_id: course.id,
          user_id: enrollment.user_id,
          learning_evaluation: true,
          deleted: true,
        }
      ).to_return Stub.json([
        build(:'course:enrollment', :with_learning_evaluation,
          course_id: course.id,
          user_id: enrollment.user_id),
      ])
      create(:roa, course:, user:, template:)
    end

    it 'does not delete the certificate template' do
      expect { delete_template }.not_to change(Certificate::Template, :count).from(1)
      expect(delete_stub).not_to have_been_requested
      expect(response).to redirect_to "/courses/#{course.course_code}/certificate_templates"
      expect(flash[:error].first).to eq "Can't delete the template due to already existing records."
    end
  end

  context 'without permission to manage certificate templates' do
    let(:permissions) { %w[course.content.access] }

    it 'redirects the user' do
      delete_template
      expect(response).to redirect_to '/'
    end
  end

  context 'without permission to access content' do
    let(:permissions) { %w[certificate.template.manage] }

    it 'redirects the user' do
      delete_template
      expect(response).to redirect_to "/courses/#{course.course_code}"
    end
  end

  context 'for anonymous users' do
    let(:headers) { {} }

    it 'redirects the user' do
      delete_template
      expect(response).to redirect_to "/courses/#{course.course_code}"
    end
  end
end

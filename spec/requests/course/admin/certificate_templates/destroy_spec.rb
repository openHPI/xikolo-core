# frozen_string_literal: true

require 'spec_helper'

describe 'Course: Admin: Certificate Templates: Destroy', type: :request do
  subject(:delete_template) do
    delete "/learn/#{course.course_code}/certificate_templates/#{template.id}"
  end

  let(:permissions) { %w[certificate.template.manage course.content.access] }
  let(:user) { create(:'account_service/user') }
  let(:course) { create(:course, records_released: true) }
  let(:authenticate) { true }
  let(:course_resource) { build(:'course:course', course_code: course.course_code) }
  let!(:template) do
    create(:certificate_template, :roa,
      course:,
      file_uri: 's3://xikolo-certificate/templates/abc.svg')
  end
  let!(:delete_stub) do
    stub_request(
      :delete,
      "#{test_s3_host}/xikolo-certificate/templates/abc.svg"
    ).to_return(status: 200)
  end

  before do
    sign_in(user:) if authenticate
    role = create(:'account_service/role', permissions:)
    create(:'account_service/grant', principal: user, role:)

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
      account_user = create(:'account_service/user')
      user = AccountService::User.find(account_user.id)
      create(:'course_service/enrollment', :with_evaluation, course_id: course.id, user_id: user.id, deleted: false)
      create(:roa, course:, user:, template:)
    end

    it 'does not delete the certificate template' do
      expect { delete_template }.not_to change(Certificate::Template, :count).from(1)
      expect(delete_stub).not_to have_been_requested
      expect(response).to redirect_to "/learn/#{course.course_code}/certificate_templates"
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
      expect(response).to redirect_to "/learn/#{course.course_code}"
    end
  end

  context 'for anonymous users' do
    let(:authenticate) { false }

    it 'redirects the user' do
      delete_template
      expect(response).to redirect_to "/learn/#{course.course_code}"
    end
  end
end

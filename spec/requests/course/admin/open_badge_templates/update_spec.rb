# frozen_string_literal: true

require 'spec_helper'

describe 'Course: Admin: Open Badge Templates: Update', type: :request do
  subject(:update_template) do
    patch "/courses/#{course.course_code}/open_badge_templates/#{template.id}",
      params: {open_badge_template: params},
      headers:
  end

  let(:user) { create(:user) }
  let(:headers) { {'Authorization' => "Xikolo-Session session_id=#{stub_session_id}"} }
  let(:permissions) { %w[course.content.access certificate.template.manage] }
  let(:course) { create(:course) }
  let(:course_resource) { build(:'course:course', course_code: course.course_code, id: course.id) }
  let(:template) do
    create(:open_badge_template,
      course:,
      name: 'Open Badge Template No. 1')
  end
  let(:params) { {name: 'Open Badge Template No. 99'} }

  before do
    stub_user_request(permissions:, id: user.id)

    Stub.service(:course, build(:'course:root'))
    Stub.request(:course, :get, "/courses/#{course.course_code}")
      .to_return Stub.json(course_resource)
  end

  context 'for anonymous users' do
    let(:headers) { {} }

    it 'redirects the user' do
      update_template
      expect(response).to redirect_to "/courses/#{course.course_code}"
    end
  end

  context 'for a logged-in user' do
    context 'without permissions to manage badge templates' do
      let(:permissions) { %w[course.content.access] }

      it 'redirects the user' do
        update_template
        expect(response).to redirect_to '/'
      end
    end

    context 'without permissions to access content' do
      let(:permissions) { %w[certificate.template.manage] }

      it 'redirects the user' do
        update_template
        expect(response).to redirect_to "/courses/#{course.course_code}"
      end
    end

    context 'with permissions' do
      let(:file_url) do
        'https://s3.xikolo.de/xikolo-uploads/' \
          'uploads/f13d30d3-6369-4816-9695-af5318c8ac15/template.png'
      end
      let(:upload_id) { 'f13d30d3-6369-4816-9695-af5318c8ac15' }
      let(:open_badge) { create(:open_badge, template_id: template.id, record:) }
      let(:record) { create(:roa, course_id: course.id, user:) }
      let(:course) { create(:course, records_released: true) }

      let(:delete_stub) do
        stub_request(:post, 'https://s3.xikolo.de/xikolo-certificate?delete')
          .with(body:
            "<Delete xmlns=\"http://s3.amazonaws.com/doc/2006-03-01/\"><Object><Key>openbadges/#{UUID4(record.user_id).to_s(format: :base62)}/#{UUID4(record.id).to_s(format: :base62)}.png</Key></Object></Delete>")
          .to_return(status: 200, body: '<Response>Success</Response>', headers: {})
      end

      before do
        Stub.request(
          :course, :get, '/enrollments',
          query: {user_id: user.id, course_id: course.id, deleted: true, learning_evaluation: true}
        ).to_return(
          Stub.json(
            build_list(
              :'course:enrollment', 1, :with_learning_evaluation,
              course_id: course.id,
              user_id: user.id,
              completed_at: '2001-02-03'
            )
          )
        )

        stub_request(:head, file_url).to_return(
          status: 200,
          headers: {
            'Content-Type' => 'inode/x-empty',
            'X-Amz-Meta-Xikolo-Purpose' => 'certificate_openbadge_template',
            'X-Amz-Meta-Xikolo-State' => 'accepted',
          }
        )

        stub_request(:get,
          'https://s3.xikolo.de/xikolo-uploads?list-type=2&' \
          "prefix=uploads%2F#{upload_id}")
          .to_return(
            status: 200,
            headers: {'Content-Type' => 'Content-Type: application/xml'},
            body: <<~XML)
              <?xml version="1.0" encoding="UTF-8"?>
              <ListBucketResult xmlns="http://s3.amazonaws.com/doc/2006-03-01/">
                <Name>xikolo-uploads</Name>
                <Prefix>uploads/#{upload_id}</Prefix>
                <IsTruncated>false</IsTruncated>
                <Contents>
                  <Key>uploads/#{upload_id}/template.png</Key>
                  <LastModified>2018-08-02T13:27:56.768Z</LastModified>
                  <ETag>&#34;d41d8cd98f00b204e9800998ecf8427e&#34;</ETag>
                </Contents>
              </ListBucketResult>
            XML
        stub_request(:put, %r{
          https://s3.xikolo.de/xikolo-certificate/openbadge_templates/[0-9a-zA-Z]+.png
        }x).to_return(status: 200, body: '<xml></xml>')
        delete_stub
        open_badge
      end

      it 'updates the Open Badge template' do
        expect { update_template }.to change { template.reload.name }
          .from('Open Badge Template No. 1')
          .to('Open Badge Template No. 99')
        expect(response).to redirect_to "/courses/#{course.course_code}/open_badge_templates"
      end

      context 'when updating the badge template' do
        let(:params) { {file_upload_id: upload_id} }

        it 'updates the template accordingly and purges the old one' do
          expect { update_template }.to change { template.reload.file_uri }
            .from('s3://xikolo-certificate/openbadge_templates/1YLgUE6KPhaxfpGSZ.png')
            .to("s3://xikolo-certificate/openbadge_templates/#{UUID4(template.id).to_s(format: :base62)}.png")
          expect(response).to redirect_to "/courses/#{course.course_code}/open_badge_templates"
          expect(delete_stub).to have_been_requested
        end
      end
    end
  end
end

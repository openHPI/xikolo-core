# frozen_string_literal: true

require 'spec_helper'

describe Home::GoController, type: :controller do
  describe 'links' do
    before do
      Stub.service(
        :account,
        session_url: '/sessions/{id}'
      )
    end

    describe 'GET #redirect' do
      subject(:action) { get :redirect, params: }

      let(:params) { {url:, checksum:} }
      let(:url) { 'http://www.google.de' }
      let(:checksum) { Xikolo::Common::Tracking::ExternalLink.new(url).checksum }

      it 'redirects to provided URL' do
        expect(action).to redirect_to url
      end

      context 'with invalid checksum' do
        let(:checksum) { '1234' }

        it { is_expected.to have_http_status :forbidden }
      end
    end
  end

  describe 'items' do
    let(:item_id) { '0c6aa55e-3010-4bc4-a2a8-72239b1e4580' }
    let(:item_short_id) { 'nqE0plonSS3asMdUtJmes' }
    let(:course_id) { '904d7f56-7da7-4f43-8c53-21325a73daa7' }
    let(:course_code) { 'test_course' }
    let(:tag_id) { '3acb134f-8595-475f-9c51-c94fb5115b8a' }
    let(:params) { {id: item_id} }

    before do
      Stub.service(
        :course,
        course_url: '/courses/{id}',
        item_url: '/items/{id}'
      )
      Stub.request(
        :course, :get, "/items/#{item_id}"
      ).to_return Stub.json({
        id: item_id,
        course_id:,
      })
      Stub.request(
        :course, :get, "/courses/#{course_id}"
      ).to_return Stub.json({
        id: course_id,
        course_code:,
      })
      Stub.service(
        :pinboard,
        tags_url: '/tags{?type,course_id,name}'
      )
      Stub.request(
        :pinboard, :get, '/tags',
        query: {type: 'ImplicitTag', course_id:, name: item_id}
      ).to_return Stub.json([
        {id: tag_id, name: item_id, course_id:},
      ])
    end

    describe 'GET #pinboard' do
      subject(:action) { get :pinboard, params: }

      it 'redirects to the filtered pinboard page' do
        expect(action).to redirect_to course_pinboard_index_path(course_id: course_code, tags: tag_id)
      end
    end

    describe 'GET #show' do
      subject(:action) { get :item, params: }

      it 'redirects to the item page in course' do
        expect(action).to redirect_to course_item_path(course_id: course_code, id: item_short_id)
      end
    end
  end
end

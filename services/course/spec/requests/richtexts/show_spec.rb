# frozen_string_literal: true

require 'spec_helper'

describe 'Richtext: Show', type: :request do
  subject(:richtext_show) do
    service.rel(:richtext).get(params).value!
  end

  let(:service) { Restify.new(course_service.root_url).get.value! }
  let(:params) { {id: richtext.id} }
  let(:text) { 'Some Text' }
  let(:course) { create(:'course_service/course', description: course_description) }
  let(:richtext) { create(:'course_service/richtext', text:, course:) }
  let(:course_description) { 'Headline!' }

  it { is_expected.to respond_with :ok }

  it { is_expected.to include('id', 'text') }

  describe '#text' do
    let(:text) { 'some text\ns3://xikolo-public/courses/34/rtfiles/34/hans.jpg' }

    it 'returns text with public URLs' do
      expect(richtext_show['text']).to eq 'some text\nhttps://s3.xikolo.de/xikolo-public/courses/34/rtfiles/34/hans.jpg'
    end

    context 'in raw mode' do
      let(:params) { super().merge raw: true }

      it 'returns the text enhanced with url mappings and other files references' do
        expect(richtext_show['text']).to eq('some text\\nhttps://s3.xikolo.de/xikolo-public/courses/34/rtfiles/34/hans.jpg')
      end

      context 'with other files in course' do
        let(:course_description) { "Headline\ns3://xikolo-public/courses/34/rtfiles/1/desc.jpg" }

        before do
          create(:'course_service/richtext', course:, text: 'Stuff: s3://xikolo-public/courses/34/rtfiles/2/item.jpg')
          create(:'course_service/richtext', text: 'Stuff: s3://xikolo-public/courses/21/rtfiles/4/wrongCourse.jpg')
        end

        it 'returns existings file references of course description and other richtext items' do
          expect(richtext_show['text']).to eq('some text\\nhttps://s3.xikolo.de/xikolo-public/courses/34/rtfiles/34/hans.jpg')
        end
      end
    end
  end
end

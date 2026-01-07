# frozen_string_literal: true

require 'spec_helper'

describe 'Course\'s teacher text', type: :request do
  let(:api) { restify_with_headers(course_service.root_url).get.value }
  let!(:course) { create(:'course_service/course', course_params) }
  let(:teachers) { create_list(:'course_service/teacher', 5).shuffle }
  let(:course_params) { {teacher_ids: teachers.map(&:id)} }

  before do
    stub_request(:get, %r{\Ahttp://richtext.xikolo.tld/rich_texts/[-0-9a-f]+\z})
      .and_return(Stub.json({markup: 'Empty'}))
  end

  describe '#show' do
    subject { api.rel(:course).get({id: course.id}).value['teacher_text'] }

    context 'with alternative_teacher_text' do
      let(:alternative_teacher_text) { 'Viele Teachers' }
      let(:course_params) { super().merge alternative_teacher_text: }

      it { is_expected.to eq alternative_teacher_text }
    end

    context 'without alternative_teacher_text' do
      it { is_expected.to eq teachers.map(&:name).join(', ') }
    end

    context 'with empty alternative_teacher_text' do
      let(:alternative_teacher_text) { '' }
      let(:course_params) { super().merge alternative_teacher_text: }

      it { is_expected.to eq teachers.map(&:name).join(', ') }
    end
  end

  describe '#index' do
    subject { api.rel(:courses).get.value.first['teacher_text'] }

    context 'with alternative_teacher_text' do
      let(:alternative_teacher_text) { 'Viele Teachers' }
      let(:course_params) { super().merge alternative_teacher_text: }

      it { is_expected.to eq alternative_teacher_text }
    end

    context 'without alternative_teacher_text' do
      it { is_expected.to eq teachers.map(&:name).join(', ') }
    end

    context 'with empty alternative_teacher_text' do
      let(:alternative_teacher_text) { '' }
      let(:course_params) { super().merge alternative_teacher_text: }

      it { is_expected.to eq teachers.map(&:name).join(', ') }
    end
  end
end

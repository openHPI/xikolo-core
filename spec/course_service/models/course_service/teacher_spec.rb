# frozen_string_literal: true

require 'spec_helper'
require 'xikolo/s3'

describe CourseService::Teacher do
  subject(:teacher) { create(:'course_service/teacher', attributes) }

  let(:attributes) { {} }

  it { is_expected.to accept_values_for(:description, {de: 'Beschreibung'}, {de: 'Beschreibung', en: 'explanation'}) }
  it { is_expected.not_to accept_values_for(:description, {}, {de: ''}, {de: ' '}, {en: '  ', de: ''}, nil, 42) }

  describe '#picture_url' do
    subject(:teacher_picture_url) { teacher.picture_url }

    context 'without picture URI' do
      let(:attributes) { {picture_uri: nil} }

      it { is_expected.to be_nil }
    end

    context 'with picture URI' do
      let(:attributes) { {picture_uri: 's3://xikolo-public/teacher/encodedTeacherId/encodedUUUID/picture.png'} }

      it {
        expect(teacher_picture_url).to eq \
          'https://s3.xikolo.de/xikolo-public/teacher/encodedTeacherId/encodedUUUID/picture.png'
      }
    end
  end

  describe 'callbacks' do
    context 'with courses present' do
      before do
        create_list(:'course_service/course', 2, teacher_ids: [teacher.id])
      end

      context 'when name is updated' do
        it 'schedules the update of search index for each course' do
          expect { teacher.update!(name: 'John John') }.to change { CourseService::UpdateCourseSearchIndexWorker.jobs.count }.by(2)
        end
      end

      context 'when other attributes than name are updated' do
        it 'does not schedule the update of search index' do
          expect { teacher.update!(description: {'de' => 'Toller Lehrer', 'en' => 'A great teacher'}) }.not_to change { CourseService::UpdateCourseSearchIndexWorker.jobs.count }
        end
      end

      context 'when teacher is destroyed' do
        it 'schedules the worker to update related courses' do
          expect { teacher.destroy }.to change { CourseService::UpdateCourseSearchIndexWorker.jobs.count }.by(2)
        end
      end
    end

    context 'without courses' do
      it 'does not schedule the update of search index' do
        expect { teacher.update!(name: 'John Doe') }.not_to change { CourseService::UpdateCourseSearchIndexWorker.jobs.count }
      end
    end
  end
end

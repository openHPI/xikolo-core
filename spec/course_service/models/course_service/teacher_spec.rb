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
          "#{test_s3_host}/xikolo-public/teacher/encodedTeacherId/encodedUUUID/picture.png"
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
          expect { teacher.update!(name: 'John John') }.to change { ActiveJob::Base.queue_adapter.enqueued_jobs.count }.by(2)
        end
      end

      context 'when other attributes than name are updated' do
        it 'does not schedule the update of search index' do
          expect { teacher.update!(description: {'de' => 'Toller Lehrer', 'en' => 'A great teacher'}) }.not_to change { ActiveJob::Base.queue_adapter.enqueued_jobs.count }
        end
      end
    end

    context 'without courses' do
      it 'does not schedule the update of search index' do
        expect { teacher.update!(name: 'John Doe') }.not_to change { ActiveJob::Base.queue_adapter.enqueued_jobs.count }
      end
    end
  end

  describe '#destroy' do
    context 'when teacher is referenced in a course' do
      before { teacher }

      it 'does not delete the teacher and adds an error' do
        create(:'course_service/course', teacher_ids: [teacher.id])

        expect { teacher.destroy }.not_to change(described_class, :count)
        expect(teacher.errors.details[:base]).to include(error: :still_referenced)
      end
    end

    context 'when teacher is not referenced in any course' do
      before { teacher }

      it 'deletes the teacher' do
        expect { teacher.destroy }.to change(described_class, :count).by(-1)
      end
    end
  end

  describe '#localized_description' do
    subject(:localized_description) { teacher.localized_description }

    let(:attributes) { {description: {'de' => 'Ein großartiger Lehrer', 'en' => 'A great teacher'}} }

    it 'returns the description for the current locale' do
      I18n.with_locale(:de) { expect(localized_description).to eq 'Ein großartiger Lehrer' }
    end

    context 'when the current locale is not available' do
      let(:attributes) { {description: {'en' => 'A great teacher'}} }

      it 'falls back to an available locale' do
        I18n.with_locale(:de) { expect(localized_description).to eq 'A great teacher' }
      end
    end
  end
end

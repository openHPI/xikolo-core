# frozen_string_literal: true

require 'spec_helper'

describe Classifier, type: :model do
  subject(:classifier) { create(:'course_service/classifier') }

  describe '(validations)' do
    it do
      expect(classifier).to accept_values_for :title,
        'Databases', 'Introduction Courses',
        'Databases 2023', 'Databases_2023',
        'Databases-SQL'
    end

    it do
      expect(classifier).not_to accept_values_for :title,
        nil, ' ', 'Introduction: Courses', 'Databases (2023)'
    end

    it do
      expect(classifier).to accept_values_for :descriptions,
        {en: 'Some description'},
        {}
    end

    it do
      expect(classifier).to accept_values_for :translations,
        {en: 'English translation'},
        {en: 'English translation', de: 'Deutsche Übersetzung'}
    end

    it do
      expect(classifier).not_to accept_values_for :translations,
        {de: 'Deutsche Übersetzung'},
        {}
    end
  end

  describe '(callbacks)' do
    context 'without courses' do
      it 'does not raise an error' do
        expect { classifier.update!(title: 'Java') }.not_to raise_error
        expect { classifier.update!(title: 'Java') }.not_to change { UpdateCourseSearchIndexWorker.jobs.count }
      end
    end

    context 'with courses present' do
      before do
        create_list(:'course_service/course', 2, classifiers: [classifier])
      end

      context 'when updating a classifier' do
        it 'schedules the update course search index worker or each course' do
          expect { classifier.update!(title: 'Java') }.to change { UpdateCourseSearchIndexWorker.jobs.count }.by(2)
        end
      end

      context 'when destroying a classifier' do
        it 'schedules the update course search index worker for each course' do
          expect { classifier.destroy }.to change { UpdateCourseSearchIndexWorker.jobs.count }.by(2)
        end
      end
    end
  end
end

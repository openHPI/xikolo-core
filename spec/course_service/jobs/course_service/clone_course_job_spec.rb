# frozen_string_literal: true

require 'spec_helper'

describe CourseService::CloneCourseJob, type: :job do
  let(:old_course_id) { '81187fa1-6cfd-4b90-a547-b546e24258b7' }
  let(:new_course_code) { 'course-CLONE' }

  let(:payload) do
    {
      old_course_id: old_course_id,
      new_course_code: new_course_code,
    }
  end

  describe '#perform' do
    it 'passes old_course_id and new_course_code to the handler' do
      operation_double = instance_double(CourseService::Course::Clone)

      allow(CourseService::Course::Clone)
        .to receive(:new)
        .with(old_course_id, new_course_code)
        .and_return(operation_double)

      expect(operation_double).to receive(:call)

      described_class.new.perform(payload)
    end
  end
end

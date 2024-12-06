# frozen_string_literal: true

require 'spec_helper'

describe CourseConsumer do
  before { Msgr.client.start }

  let(:consumer) { described_class.new }
  let(:old_course_id) { '81187fa1-6cfd-4b90-a547-b546e24258b7' }
  let(:new_course_code) { 'course-CLONE' }

  let(:payload) { {old_course_id:, new_course_code:} }
  let(:publish) { -> { Msgr.publish(payload, to: 'xikolo.course.clone') } }

  describe '#clone' do
    it 'passes old_course_id and new_course_code to the handler' do
      operation_double = instance_double(Course::Clone)

      allow(Course::Clone).to receive(:new)
        .with(old_course_id, new_course_code)
        .and_return(operation_double)

      expect(operation_double).to receive(:call)

      publish.call
      Msgr::TestPool.run count: 1
    end
  end
end

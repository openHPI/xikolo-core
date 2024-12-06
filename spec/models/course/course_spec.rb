# frozen_string_literal: true

require 'spec_helper'

describe Course::Course, type: :model do
  let(:course) { create(:course, middle_of_course: moc) }
  let(:moc) { nil }

  describe '#middle_of_course' do
    context 'with a fixed course middle' do
      let(:moc) { Time.new(2023, 1, 1, 9, 0, 0).utc }

      it 'returns the specified date for the course middle' do
        expect(course.middle_of_course).to be_an_instance_of(ActiveSupport::TimeWithZone)
      end
    end

    context 'without a fixed course middle' do
      it 'calculates the course middle based on the start and end dates' do
        expect(course.middle_of_course).to be_an_instance_of(ActiveSupport::TimeWithZone)
      end

      context 'but no start and/or end date' do
        let(:course) { create(:course, start_date: nil, end_date: nil) }

        it 'cannot calculate the course middle' do
          expect(course.middle_of_course).to be_nil
        end
      end
    end
  end
end

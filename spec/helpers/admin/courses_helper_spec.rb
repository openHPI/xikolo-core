# frozen_string_literal: true

require 'spec_helper'

describe Admin::CoursesHelper, type: :helper do
  describe '#course_status_class' do
    {
      'active'       => 'x-badge-success',
      'preparation'  => 'x-badge-info',
      'self-paced' => 'x-badge-neutral',
      'upcoming' => 'x-badge-neutral',
      'unknown' => '',
    }.each do |status, css_class|
      it "returns #{css_class.inspect} for #{status}" do
        expect(helper.course_status_class(status)).to eq(css_class)
      end
    end
  end
end

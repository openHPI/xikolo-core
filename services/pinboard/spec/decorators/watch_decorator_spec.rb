# frozen_string_literal: true

require 'spec_helper'

describe WatchDecorator, type: :decorator do
  subject { json }

  let(:watch) { create(:watch) }
  let(:decorator) { described_class.new(watch) }

  describe '#to_event' do
    let(:json) { decorator.to_event.stringify_keys }

    it { is_expected.to include('id') }
    it { is_expected.to include('user_id') }
    it { is_expected.to include('question_id') }
    it { is_expected.to include('course_id') }
    it { is_expected.to include('created_at') }
    it { is_expected.to include('updated_at') }

    describe "['course_id']" do
      subject { super()['course_id'] }

      it { is_expected.to be watch.question.course_id }
    end
  end
end

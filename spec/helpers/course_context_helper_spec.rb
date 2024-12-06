# frozen_string_literal: true

require 'spec_helper'

class SimpleApplicationController
  include CourseContextHelper
  def promises
    @promises ||= {}
  end
end

describe CourseContextHelper, type: :helper do
  let(:instance) { SimpleApplicationController.new }

  describe '#the_section_nav' do
    context 'without loaded section nav' do
      it 'raises an exception' do
        expect { instance.the_section_nav }.to \
          raise_exception(RuntimeError, 'Section nav not loaded!')
      end
    end

    context 'with loaded section nav' do
      let(:double) { Object.new }

      before { instance.promises[:section_nav] = double }

      it 'returns the loaded section nav' do
        expect(instance.the_section_nav).to eql double
      end
    end
  end
end

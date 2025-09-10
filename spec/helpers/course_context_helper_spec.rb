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

  describe '#the_table_of_content' do
    context 'without loaded table of content' do
      it 'raises an exception' do
        expect { instance.the_table_of_content }.to \
          raise_exception(RuntimeError, 'Table of content not loaded!')
      end
    end

    context 'with loaded section nav' do
      let(:double) { Object.new }

      before { instance.promises[:table_of_content] = double }

      it 'returns the loaded section nav' do
        expect(instance.the_table_of_content).to eql double
      end
    end
  end
end

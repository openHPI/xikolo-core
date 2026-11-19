# frozen_string_literal: true

require 'spec_helper'

describe SvgHelper, type: :helper do
  describe '#pixelart_icon' do
    context 'when icon exists' do
      it 'renders svg with default css classes' do
        result = helper.pixelart_icon('t-rex')

        expect(result).to include('class="w-6 h-6"')
        expect(result).to include('fill="currentColor"')
        expect(result).to be_html_safe
      end

      it 'allows custom css classes' do
        result = helper.pixelart_icon('t-rex', css_class: 'w-8 h-8 text-blue-500')

        expect(result).to include('class="w-8 h-8 text-blue-500"')
      end
    end

    context 'when icon is missing' do
      it 'raises Errno::ENOENT' do
        expect {
          helper.pixelart_icon('non_existent_icon')
        }.to raise_error(Errno::ENOENT)
      end
    end
  end
end

# frozen_string_literal: true

require 'spec_helper'
require 'rake'

RSpec.describe 'dynamic_content:remove_invalid_content' do
  subject(:remove_invalid_content) do
    Rake.application.invoke_task 'dynamic_content:remove_invalid_content'
  end

  # rubocop:disable RSpec/BeforeAfterAll
  before(:all) { Rails.application.load_tasks if Rake::Task.tasks.empty? }
  # rubocop:enable RSpec/BeforeAfterAll

  context 'when there are certificates with invalid dynamic content' do
    let(:invalid_content) do
      '<?xml version="1.0" encoding="utf-8"?>
        <!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1 Basic//EN" "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11-basic.dtd">
        <svg version="1.1" baseProfile="basic" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" x="0px" y="0px" width="842" height="595" viewBox="0 0 842 595" xml:space="preserve">
          <g id="Dynamic data">
            <text fill="#C82B4A" stroke="#C82B4A" stroke-width="0" x="128.90" y="153.04" font-size="21.6" font="OpenSansRegular" text-anchor="left" xml:space="preserve">##NAME##</text>
            <text fill="#3B3939" stroke="#3B3939" stroke-width="0" x="128.90" y="174.26" font-size="14.4" font="OpenSansRegular" text-anchor="left" xml:space="preserve">##EMAIL##</text>
            <text fill="#3B3939" stroke="#3B3939" stroke-width="0" x="128.90" y="197.26" font-size="14.4" font="OpenSansRegular" text-anchor="left" xml:space="preserve">##AFFILIATION##</text>
            <text fill="#3B3939" stroke="#3B3939" stroke-width="0" x="128.90" y="215.138" font-size="14.4" font="OpenSansRegular" text-anchor="left" xml:space="preserve">##BIRTHDAY##</text>
            <text fill="#3B3939" stroke="#3B3939" stroke-width="0" x="131.9" y="432.37" font-size="8" font="OpenSansRegular" text-anchor="left" xml:space="preserve">##GRADE##</text>
            <text fill="#3B3939" stroke="#3B3939" strokewidth="0" x="131.9" y="453.37" fontsize="8" fontfamily="OpenSansRegular" textanchor="left" xml:space="preserve">##TOP##</text>
          </g>
        </svg>'
    end
    let(:expected_content) do
      '<?xml version="1.0" encoding="utf-8"?>
        <!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1 Basic//EN" "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11-basic.dtd">
        <svg version="1.1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" x="0px" y="0px" width="842" height="595" viewBox="0 0 842 595" xml:space="preserve">
          <g id="dynamic-data">
            <text fill="#C82B4A" stroke="#C82B4A" stroke-width="0" x="128.90" y="153.04" font-size="21.6" font-family="OpenSansRegular" text-anchor="start" xml:space="preserve">##NAME##</text>
            <text fill="#3B3939" stroke="#3B3939" stroke-width="0" x="128.90" y="174.26" font-size="14.4" font-family="OpenSansRegular" text-anchor="start" xml:space="preserve">##EMAIL##</text>
            <text fill="#3B3939" stroke="#3B3939" stroke-width="0" x="128.90" y="197.26" font-size="14.4" font-family="OpenSansRegular" text-anchor="start" xml:space="preserve">##AFFILIATION##</text>
            <text fill="#3B3939" stroke="#3B3939" stroke-width="0" x="128.90" y="215.138" font-size="14.4" font-family="OpenSansRegular" text-anchor="start" xml:space="preserve">##BIRTHDAY##</text>
            <text fill="#3B3939" stroke="#3B3939" stroke-width="0" x="131.9" y="432.37" font-size="8" font-family="OpenSansRegular" text-anchor="start" xml:space="preserve">##GRADE##</text>
            <text fill="#3B3939" stroke="#3B3939" stroke-width="0" x="131.9" y="453.37" font-size="8" font-family="OpenSansRegular" text-anchor="start" xml:space="preserve">##TOP##</text>
          </g>
        </svg>'
    end

    let!(:invalid_template) do
      create(:certificate_template).tap {|t| t.update_columns(dynamic_content: invalid_content) }
    end

    it 'removes invalid content' do
      remove_invalid_content

      # Check that the template content has been updated to the expected content
      expect(invalid_template.reload.dynamic_content).to eq(expected_content)
    end
  end
end

# frozen_string_literal: true

require 'spec_helper'
require 'xui/form'

RSpec.describe 'Attribute Type: list' do
  let(:form) do
    Class.new(XUI::Form) do
      self.form_name = 'test'

      attribute :names, :list, subtype: :single_line_string
    end
  end

  describe 'instantiation from a form submission' do
    it 'accepts a list' do
      object = form.from_params 'names' => %w[otto hans]

      expect(object.names).to eq %w[otto hans]
      expect(object).to be_valid
    end

    it 'ignores list items that would be ignored by the subtype' do
      object = form.from_params 'names' => ['otto', '', '    ']

      expect(object.names).to eq ['otto']
      expect(object).to be_valid
    end
  end

  describe 'instantiation from a service resource' do
    it 'accepts a list' do
      object = form.from_resource 'names' => %w[otto hans]

      expect(object.names).to eq %w[otto hans]
    end

    it 'converts nil to empty list' do
      object = form.from_resource 'names' => nil

      expect(object.names).to eq []
    end

    it 'keeps list items that would be ignored by the subtype' do
      object = form.from_resource 'names' => ['otto', '', '    ']

      expect(object.names).to eq ['otto', nil, nil]
    end

    it 'applies subtype transformation' do
      object = form.from_resource 'names' => ["Hans\r\nOtto"]

      expect(object.names).to eq ["Hans\nOtto"]
    end
  end
end

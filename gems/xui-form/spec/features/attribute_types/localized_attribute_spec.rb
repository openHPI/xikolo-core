# frozen_string_literal: true

require 'spec_helper'
require 'xui/form'

RSpec.describe 'Attribute Type: localized_attribute' do
  let(:form) do
    Class.new(XUI::Form) do
      self.form_name = 'test'

      localized_attribute :s, :markup, locales: %i[en de]
    end
  end

  describe '#to_resource' do
    it 'returns input as hash' do
      object = form.from_params 's_en' => 'otto', 's_de' => 'hans'

      expect(object.to_resource).to eq(
        's' => {
          'en' => 'otto',
          'de' => 'hans',
        }
      )
    end

    it 'removes keys with blank values' do
      object = form.from_params 's_en' => '     ', 's_de' => nil

      expect(object.to_resource).to eq('s' => {})
    end
  end

  describe 'instantiation from a form submission' do
    it 'does not accept a hash' do
      object = form.from_params 's' => {'en' => 'otto', 'de' => 'hans'}

      expect(object.s_en).to be_nil
      expect(object.s_de).to be_nil
      expect(object).to be_valid
    end

    it 'accepts the serialized parameter keys' do
      object = form.from_params 's_en' => 'otto', 's_de' => 'hans'

      expect(object.s_en).to eq 'otto'
      expect(object.s_de).to eq 'hans'
      expect(object).to be_valid
    end
  end

  describe 'instantiation from a service resource' do
    it 'accepts a hash as input' do
      object = form.from_resource 's' => {'en' => 'otto', 'de' => 'hans'}

      expect(object.s_en).to eq 'otto'
      expect(object.s_de).to eq 'hans'
      expect(object).to be_valid
    end

    it 'does not accept the serialized parameter keys' do
      object = form.from_resource 's_en' => 'otto', 's_de' => 'hans'

      expect(object.s_en).to be_nil
      expect(object.s_de).to be_nil
      expect(object).to be_valid
    end
  end
end

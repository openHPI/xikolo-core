# frozen_string_literal: true

require 'spec_helper'
require 'xui/form'

RSpec.describe 'Attribute Type: hash_attribute' do
  let(:form) do
    keys = attribute_keys
    Class.new(XUI::Form) do
      self.form_name = 'test'

      hash_attribute(:s, :markup, keys:)

      instance_count = 0
      define_method(:field_names) do
        Array.new(instance_count += 1) {|i| "field#{i}" }
      end
    end
  end
  let(:attribute_keys) { %i[main bonus selftest] }

  describe '#to_resource' do
    it 'returns input as hash' do
      object = form.from_params 's_main' => 'otto', 's_bonus' => 'hans'

      expect(object.to_resource).to eq(
        's' => {
          'main' => 'otto',
          'bonus' => 'hans',
        }
      )
    end

    it 'removes keys with blank values' do
      object = form.from_params 's_main' => '', 's_bonus' => ' ', 'selftest' => nil

      expect(object.to_resource).to eq('s' => {})
    end
  end

  describe 'instantiation from a form submission' do
    it 'does not accept a hash' do
      object = form.from_params 's' => {'main' => 'otto', 'bonus' => 'hans'}

      expect(object.s_main).to be_nil
      expect(object.s_bonus).to be_nil
      expect(object.s_selftest).to be_nil
      expect(object).to be_valid
    end

    it 'accepts the serialized parameter keys' do
      object = form.from_params 's_main' => 'otto', 's_bonus' => 'hans'

      expect(object.s_main).to eq 'otto'
      expect(object.s_bonus).to eq 'hans'
      expect(object.s_selftest).to be_nil
      expect(object).to be_valid
    end
  end

  describe 'instantiation from a service resource' do
    it 'accepts a hash as input' do
      object = form.from_resource 's' => {'main' => 'otto', 'bonus' => 'hans'}

      expect(object.s_main).to eq 'otto'
      expect(object.s_bonus).to eq 'hans'
      expect(object.s_selftest).to be_nil
      expect(object).to be_valid
    end

    it 'does not accept the serialized parameter keys' do
      object = form.from_resource 's_main' => 'otto', 's_bonus' => 'hans'

      expect(object.s_main).to be_nil
      expect(object.s_bonus).to be_nil
      expect(object.s_selftest).to be_nil
      expect(object).to be_valid
    end
  end

  describe 'static keys in proc' do
    let(:attribute_keys) { proc { %i[main bonus selftest] } }

    it 'generates methods to access the sub-keys as the form builder would do' do
      object = form.new

      expect(object.s_main).to eq nil
      expect(object.s_bonus).to eq nil
      expect(object.s_selftest).to eq nil
      expect(object).to respond_to :s_main
      expect(object).to respond_to :s_bonus
      expect(object).to respond_to :s_selftest
    end
  end

  describe 'dynamic keys in proc' do
    let(:attribute_keys) do
      proc do
        @i ||= 0
        @i += 1
        Array.new(@i) {|i| "field#{i}" }
      end
    end

    it 'generates methods to access the sub-keys only for the calculated keys' do
      first_object = form.from_params 's_field0' => 'otto', 's_field1' => 'hans'
      second_object = form.from_params 's_field0' => 'otto', 's_field1' => 'hans'

      expect(first_object.s_field0).to eq 'otto'
      expect { first_object.s_field1 }.to raise_error(NoMethodError)

      expect(second_object.s_field0).to eq 'otto'
      expect(second_object.s_field1).to eq 'hans'
    end
  end

  describe 'dynamic keys in proc based on instance' do
    let(:attribute_keys) do
      proc {|instance| instance.field_names }
    end

    it 'generates methods to access the sub-keys only for the calculated keys' do
      first_object = form.from_params 's_field0' => 'otto', 's_field1' => 'hans'
      second_object = form.from_params 's_field0' => 'otto', 's_field1' => 'hans'

      expect(first_object.s_field0).to eq 'otto'
      expect { first_object.s_field1 }.to raise_error(NoMethodError)

      expect(second_object.s_field0).to eq 'otto'
      expect(second_object.s_field1).to eq 'hans'
    end
  end

  describe 'dynamic keys from instance method (given as symbol)' do
    let(:attribute_keys) { :field_names }

    it 'generates methods to access the sub-keys only for the calculated keys' do
      first_object = form.from_params 's_field0' => 'otto', 's_field1' => 'hans'
      second_object = form.from_params 's_field0' => 'otto', 's_field1' => 'hans'

      expect(first_object.s_field0).to eq 'otto'
      expect { first_object.s_field1 }.to raise_error(NoMethodError)

      expect(second_object.s_field0).to eq 'otto'
      expect(second_object.s_field1).to eq 'hans'
    end
  end
end

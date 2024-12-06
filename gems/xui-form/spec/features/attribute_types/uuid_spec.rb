# frozen_string_literal: true

require 'spec_helper'
require 'xui/form'

RSpec.describe 'Attribute Type: uuid' do
  let(:form) do
    Class.new(XUI::Form) do
      self.form_name = 'test'

      attribute :id, :uuid
    end
  end

  describe 'instantiation from a form submission' do
    it 'returns UUID as UUID4 instance' do
      uuid = SecureRandom.uuid
      object = form.from_params 'id' => uuid

      expect(object.id).to be_a UUID4
      expect(object.id.to_s).to eq uuid
      expect(object).to be_valid
    end

    it 'is invalid for garbage but returns it' do
      object = form.from_params 'id' => 'asdf34'

      expect(object.id).to eq 'asdf34'
      expect(object).not_to be_valid
    end

    it 'casts empty value as nil' do
      object = form.from_params 'id' => ' '

      expect(object.id).to be_nil
      expect(object).to be_valid
    end

    it 'accepts and keeps nil values' do
      object = form.from_params 'id' => nil

      expect(object.id).to be_nil
      expect(object).to be_valid
    end

    it 'sets nil for missing value' do
      object = form.from_params({})

      expect(object.id).to be_nil
      expect(object).to be_valid
    end
  end

  describe 'instantiation from a service resource' do
    it 'returns UUID as UUID4 instance' do
      uuid = SecureRandom.uuid
      object = form.from_resource 'id' => uuid

      expect(object.id).to be_a UUID4
      expect(object.id.to_s).to eq uuid
      expect(object).to be_valid
    end

    it 'ignores garbage' do
      object = form.from_resource 'id' => 'asdf34'

      expect(object.id).to be_nil
      expect(object).to be_valid
    end

    it 'casts empty value as nil' do
      object = form.from_resource 'id' => ' '

      expect(object.id).to be_nil
      expect(object).to be_valid
    end

    it 'accepts and keeps nil values' do
      object = form.from_resource 'id' => nil

      expect(object.id).to be_nil
      expect(object).to be_valid
    end

    it 'sets nil for missing value' do
      object = form.from_resource({})

      expect(object.id).to be_nil
      expect(object).to be_valid
    end
  end
end

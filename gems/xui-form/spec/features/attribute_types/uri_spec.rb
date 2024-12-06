# frozen_string_literal: true

require 'spec_helper'
require 'xui/form'

RSpec.describe 'Attribute Type: uri' do
  let(:form) do
    Class.new(XUI::Form) do
      self.form_name = 'test'

      attribute :ref, :uri
    end
  end

  describe '#to_resource' do
    it 'casts empty value as nil' do
      object = form.from_params 'ref' => ' '

      expect(object.to_resource).to eq('ref' => nil)
    end

    it 'removes leading and trailing whitespaces' do
      object = form.from_params 'ref' => ' https://xopic.de/policy.html  '

      expect(object.to_resource).to eq('ref' => 'https://xopic.de/policy.html')
    end
  end

  describe 'instantiation from a form submission' do
    it 'returns URL as URI instance' do
      url = 'https://xopic.de/policy.html'
      object = form.from_params 'ref' => url

      expect(object.ref).to be_a URI
      expect(object.ref.to_s).to eq url
      expect(object).to be_valid
    end

    it 'returns URI as URI instance' do
      uri = 's3://hans/otto.file'
      object = form.from_params 'ref' => uri

      expect(object.ref).to be_a URI
      expect(object.ref.to_s).to eq uri
      expect(object).to be_valid
    end

    it 'accepts URIs that would not be allowed as URLs' do
      uri = 'asdf34'
      object = form.from_params 'ref' => uri

      expect(object.ref).to be_a URI
      expect(object.ref.to_s).to eq uri
      expect(object).to be_valid
    end

    it 'casts empty value as nil' do
      object = form.from_params 'ref' => ' '

      expect(object.ref).to be_nil
      expect(object).to be_valid
    end

    it 'accepts and keeps nil values' do
      object = form.from_params 'ref' => nil

      expect(object.ref).to be_nil
      expect(object).to be_valid
    end

    it 'sets nil for missing value' do
      object = form.from_params({})

      expect(object.ref).to be_nil
      expect(object).to be_valid
    end

    it 'removes leading and trailing whitespaces' do
      url = 'https://xopic.de/policy.html'
      object = form.from_params 'ref' => ' https://xopic.de/policy.html  '

      expect(object.ref.to_s).to eq url
      expect(object).to be_valid
    end
  end

  describe 'instantiation from a service resource' do
    it 'returns URL as URI instance' do
      url = 'https://xopic.de/policy.html'
      object = form.from_resource 'ref' => url

      expect(object.ref).to be_a URI
      expect(object.ref.to_s).to eq url
      expect(object).to be_valid
    end

    it 'returns URI as URI instance' do
      uri = 's3://hans/otto.file'
      object = form.from_resource 'ref' => uri

      expect(object.ref).to be_a URI
      expect(object.ref.to_s).to eq uri
      expect(object).to be_valid
    end

    it 'accepts URIs that would not be allowed as URLs' do
      uri = 'asdf34'
      object = form.from_resource 'ref' => uri

      expect(object.ref).to be_a URI
      expect(object.ref.to_s).to eq uri
      expect(object).to be_valid
    end

    it 'casts empty value as nil' do
      object = form.from_resource 'ref' => ' '

      expect(object.ref).to be_nil
      expect(object).to be_valid
    end

    it 'accepts and keeps nil values' do
      object = form.from_resource 'ref' => nil

      expect(object.ref).to be_nil
      expect(object).to be_valid
    end

    it 'sets nil for missing value' do
      object = form.from_resource({})

      expect(object.ref).to be_nil
      expect(object).to be_valid
    end

    it 'removes leading and trailing whitespaces' do
      url = 'https://xopic.de/policy.html'
      object = form.from_resource 'ref' => ' https://xopic.de/policy.html  '

      expect(object.ref.to_s).to eq url
      expect(object).to be_valid
    end
  end
end

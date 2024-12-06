# frozen_string_literal: true

require 'spec_helper'
require 'xui/form'

RSpec.describe 'Attribute Type: new_upload' do
  let(:form) do
    Class.new(XUI::Form) do
      self.form_name = 'test'

      attribute :visual, :new_upload
    end
  end

  describe 'instantiation from a form submission' do
    it 'is nil by default' do
      object = form.from_params({})

      expect(object.visual).to be_nil
      expect(object).to be_valid
      expect(object.to_resource).to eq('visual' => nil)
    end

    it 'is explicitly nullable' do
      object = form.from_params 'visual_upload_id' => nil

      expect(object.visual).to be_nil
      expect(object).to be_valid
      expect(object.to_resource).to eq('visual' => nil)
    end

    context 'with a deletion parameter' do
      let(:form) do
        Class.new(XUI::Form) do
          self.form_name = 'test'

          attribute :visual, :new_upload
          attribute :delete_visual, :boolean
        end
      end

      it 'creates an uri field and deletes deletion parameter' do
        object = form.from_params 'delete_visual' => true

        expect(object).to be_valid
        expect(object.to_resource).to eq('visual_uri' => nil)
        expect(object.to_resource).not_to have_key('delete_visual')
      end

      context 'with the deletion parameter being false' do
        it 'does not create an uri field and deletes deletion parameter' do
          object = form.from_params 'delete_visual' => false

          expect(object).to be_valid
          expect(object.to_resource).not_to have_key('visual_uri')
          expect(object.to_resource).not_to have_key('delete_visual')
        end
      end
    end

    it 'wraps a given upload ID in an object' do
      id = SecureRandom.uuid
      object = form.from_params 'visual_upload_id' => id

      expect(object.visual.upload_id).to eq id
      expect(object.visual.url).to be_nil
      expect(object).to be_valid
    end

    it 'passes the upload ID to the resource' do
      id = SecureRandom.uuid
      object = form.from_params 'visual_upload_id' => id

      expect(object.to_resource).to eq('visual_upload_id' => id)
    end

    it 'ignores non-UUID IDs' do
      object = form.from_params 'visual_upload_id' => 'whatdoyoumean'

      expect(object.visual).to be_nil
      expect(object).to be_valid
    end
  end

  describe 'instantiation from a service resource' do
    it 'is nil by default' do
      object = form.from_resource({})

      expect(object.visual).to be_nil
      expect(object).to be_valid
    end

    it 'is explicitly nullable' do
      object = form.from_resource 'visual_url' => nil

      expect(object.visual).to be_nil
      expect(object).to be_valid
    end

    it 'wraps a given URL in an object' do
      object = form.from_resource 'visual_url' => 'http://my.image.host/image.png'

      expect(object.visual.upload_id).to be_nil
      expect(object.visual.url).to eq 'http://my.image.host/image.png'
      expect(object).to be_valid
    end

    it 'ignores invalid URLs' do
      object = form.from_resource 'visual_url' => '###WAT???'

      expect(object.visual).to be_nil
      expect(object).to be_valid
    end
  end
end

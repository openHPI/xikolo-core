# frozen_string_literal: true

require 'spec_helper'
require 'xui/form'

RSpec.describe 'Attribute Type: subform' do
  let(:form) do
    subform = subform_klass
    Class.new(XUI::Form) do
      self.form_name = 'test'

      attribute :subelement, :subform, klass: subform
    end
  end

  let(:subform_klass) do
    Class.new(XUI::Form) do
      self.form_name = 'subtype'

      attribute :name, :string
    end
  end

  describe '#to_resource' do
    it 'generates_a_nested_resource' do
      object = form.from_params 'subelement' => {'name' => 'Peter'}

      expect(object.to_resource).to eq('subelement' => {'name' => 'Peter'})
    end
  end

  describe 'instantiation from a form submission' do
    it 'fills the subform from a nested hash' do
      object = form.from_params 'subelement' => {'name' => 'Peter'}

      expect(object.subelement).to be_a subform_klass
      expect(object.subelement.name).to eq 'Peter'
      expect(object).to be_valid
    end
  end

  describe 'instantiation from a service resource' do
    it 'fills the subform from a nested hash' do
      object = form.from_resource 'subelement' => {'name' => 'Peter'}

      expect(object.subelement).to be_a subform_klass
      expect(object.subelement.name).to eq 'Peter'
      expect(object).to be_valid
    end

    context 'with processors' do
      let(:subform_klass) do
        Class.new(XUI::Form) do
          self.form_name = 'subtype'

          attribute :name, :string

          process_with do
            Class.new do
              def from_resource(resource, _obj)
                resource['name'] = "#{resource['name']} und der Wolf"
                resource
              end
            end.new
          end
        end
      end

      it 'passes the data through the processors' do
        object = form.from_resource 'subelement' => {'name' => 'Peter'}

        expect(object.subelement.name).to eq 'Peter und der Wolf'
      end
    end
  end

  describe 'lists of subforms' do
    let(:form) do
      subform = subform_klass
      Class.new(XUI::Form) do
        self.form_name = 'test'

        attribute :subelements, :list, subtype: :subform, subtype_opts: {klass: subform}
      end
    end

    describe '#to_resource' do
      it 'generates_a_nested_resource' do
        object = form.from_params 'subelements' => [{'name' => 'Peter'}, {'name' => 'Luise'}]

        expect(object.to_resource).to eq(
          'subelements' => [
            {'name' => 'Peter'},
            {'name' => 'Luise'},
          ]
        )
      end
    end

    describe 'instantiation from a service resource' do
      it 'fills the subform from a nested hash' do
        object = form.from_resource 'subelements' => [{'name' => 'Peter'}]

        expect(object.subelements).to be_an Array
        expect(object.subelements.first.name).to eq 'Peter'
        expect(object).to be_valid
      end

      context 'with processors' do
        let(:subform_klass) do
          Class.new(XUI::Form) do
            self.form_name = 'subtype'

            attribute :name, :string

            process_with do
              Class.new do
                def from_resource(resource, _obj)
                  resource['name'] = "#{resource['name']} und der Wolf"
                  resource
                end
              end.new
            end
          end
        end

        it 'passes the data through the processors' do
          object = form.from_resource 'subelements' => [{'name' => 'Peter'}]

          expect(object.subelements.first.name).to eq 'Peter und der Wolf'
        end
      end
    end
  end
end

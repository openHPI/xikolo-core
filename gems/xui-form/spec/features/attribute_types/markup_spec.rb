# frozen_string_literal: true

require 'spec_helper'
require 'xui/form'

RSpec.describe 'Attribute Type: markup' do
  let(:form) do
    Class.new(XUI::Form) do
      self.form_name = 'test'

      attribute :s, :markup
    end
  end

  describe 'instantiation from a form submission' do
    it 'returns a string' do
      object = form.from_params 's' => 'otto'

      expect(object.s).to eq 'otto'
      expect(object).to be_valid
    end

    it 'converts empty string to nil' do
      object = form.from_params 's' => ''

      expect(object.s).to be_nil
      expect(object).to be_valid
    end

    it 'converts blank string to nil' do
      object = form.from_params 's' => '    '

      expect(object.s).to be_nil
      expect(object).to be_valid
    end

    it 'converts newlines to unix' do
      object = form.from_params 's' => "a\r\nb"

      expect(object.s).to eq "a\nb"
      expect(object).to be_valid
    end
  end

  describe 'instantiation from a service resource' do
    it 'returns a string' do
      object = form.from_resource 's' => 'otto'

      expect(object.s).to eq 'otto'
      expect(object).to be_valid
    end

    it 'converts empty string to nil' do
      object = form.from_resource 's' => ''

      expect(object.s).to be_nil
      expect(object).to be_valid
    end

    it 'converts blank string to nil' do
      object = form.from_resource 's' => '    '

      expect(object.s).to be_nil
      expect(object).to be_valid
    end

    it 'converts newlines to unix' do
      object = form.from_resource 's' => "a\r\nb"

      expect(object.s).to eq "a\nb"
      expect(object).to be_valid
    end
  end

  context 'with uploads field' do
    let(:form) do
      Class.new(XUI::Form) do
        self.form_name = 'test'

        attribute :s, :markup, uploads: true
      end
    end

    describe '#to_resource' do
      it 'returns input string' do
        object = form.from_params 's' => 'otto'

        expect(object.to_resource).to eq('s' => 'otto')
      end

      it 'converts empty string to nil' do
        object = form.from_params 's' => ''

        expect(object.to_resource).to eq('s' => nil)
      end

      it 'converts blank string to nil' do
        object = form.from_params 's' => '    '

        expect(object.to_resource).to eq('s' => nil)
      end

      it 'converts newlines to unix' do
        object = form.from_params 's' => "a\r\nb"

        expect(object.to_resource).to eq('s' => "a\nb")
      end
    end

    describe 'instantiation from a form submission' do
      it 'returns input string as markup' do
        object = form.from_params 's' => 'otto'

        expect(object.s).to eq(
          'markup' => 'otto',
          'other_files' => {},
          'url_mapping' => {}
        )
        expect(object).to be_valid
      end

      it 'converts empty string to nil' do
        object = form.from_params 's' => ''

        expect(object.s).to eq(
          'markup' => nil,
          'other_files' => {},
          'url_mapping' => {}
        )
        expect(object).to be_valid
      end

      it 'converts blank string to nil' do
        object = form.from_params 's' => '    '

        expect(object.s).to eq(
          'markup' => nil,
          'other_files' => {},
          'url_mapping' => {}
        )
        expect(object).to be_valid
      end

      it 'converts newlines to unix' do
        object = form.from_params 's' => "a\r\nb"

        expect(object.s).to eq(
          'markup' => "a\nb",
          'other_files' => {},
          'url_mapping' => {}
        )
        expect(object).to be_valid
      end

      it 'accepts embed url mapping and other files' do
        object = form.from_params 's' => 't', 's_urlmapping' => '{"3": "4"}', 's_otherfiles' => '{"1": "2"}'

        expect(object.s).to eq(
          'markup' => 't',
          'other_files' => {'1' => '2'},
          'url_mapping' => {'3' => '4'}
        )
        expect(object).to be_valid
      end

      it 'ignores invalid url mapping and other files data' do
        object = form.from_params 's' => 't', 's_urlmapping' => '{', 's_otherfiles' => ''

        expect(object.s).to eq(
          'markup' => 't',
          'other_files' => {},
          'url_mapping' => {}
        )
        expect(object).to be_valid
      end
    end

    describe 'instantiation from a service resource' do
      it 'returns input string as markup' do
        object = form.from_resource 's' => 'otto'

        expect(object.s).to eq(
          'markup' => 'otto',
          'other_files' => {},
          'url_mapping' => {}
        )
        expect(object).to be_valid
      end

      it 'converts empty string to nil' do
        object = form.from_resource 's' => ''

        expect(object.s).to eq(
          'markup' => nil,
          'other_files' => {},
          'url_mapping' => {}
        )
        expect(object).to be_valid
      end

      it 'converts blank string to nil' do
        object = form.from_resource 's' => '    '

        expect(object.s).to eq(
          'markup' => nil,
          'other_files' => {},
          'url_mapping' => {}
        )
        expect(object).to be_valid
      end

      it 'converts newlines to unix' do
        object = form.from_resource 's' => "a\r\nb"

        expect(object.s).to eq(
          'markup' => "a\nb",
          'other_files' => {},
          'url_mapping' => {}
        )
        expect(object).to be_valid
      end

      it 'ignores embedded url mapping and other files' do
        object = form.from_resource 's' => 't', 's_urlmapping' => '{"3": "4"}', 's_otherfiles' => '{"1": "2"}'

        expect(object.s).to eq(
          'markup' => 't',
          'other_files' => {},
          'url_mapping' => {}
        )
        expect(object).to be_valid
      end
    end
  end
end

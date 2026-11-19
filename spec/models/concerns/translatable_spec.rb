# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Translatable do
  subject(:model) do
    model_class.new(
      name_translations: {
        'en' => 'English name',
        'de' => 'Deutsch name',
      },
      description_translations: {},
      title_translations: {
        'en' => 'English title',
        'de' => 'Deutsch title',
      }
    )
  end

  let(:model_class) do
    klass = Class.new do
      include ActiveModel::Model
      include Translatable

      attr_accessor :name_translations, :description_translations, :title_translations

      translated_field :name, required: true
      translated_field :title, required: :any
      translated_field :description
    end
    stub_const('TranslatableSpecModel', klass)
  end

  it 'adds accessors for localizations' do
    I18n.available_locales.each do |local|
      value = "local #{local}"
      model.public_send("name_#{local}=", value)

      expect(model.public_send("name_#{local}")).to eq value
    end
  end

  it 'updates the localization in the _translations fields' do
    model.description_en = 'English'
    model.description_de = 'Deutsch'

    expect(model.description_translations).to eq({
      'en' => 'English',
      'de' => 'Deutsch',
    })
  end

  context 'validations' do
    it 'is valid with required translations' do
      expect(model).to be_valid
    end

    it 'confirms that all translations are present when configured' do
      model.name_de = nil

      expect(model).not_to be_valid
      expect(model.errors['name_de']).to include("can't be blank")

      model.name_en = ''
      model.name_de = 'valid text'

      expect(model).not_to be_valid
      expect(model.errors['name_en']).to include("can't be blank")
    end

    it 'confirms that any translations are present when configured' do
      model.title_de = nil

      expect(model).to be_valid

      model.title_en = ' '

      expect(model).not_to be_valid
      expect(model.errors['title_en']).to include("can't be blank")
      expect(model.errors['title_de']).to include("can't be blank")
    end
  end

  context 'class methods' do
    it 'defines a class method to return the localized field names' do
      expect(model_class.localized_name_fields).to eq I18n.available_locales.map {|locale| "name_#{locale}" }
      expect(model_class.localized_description_fields).to eq I18n.available_locales.map {|locale| "description_#{locale}" }
    end
  end
end

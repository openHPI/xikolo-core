# frozen_string_literal: true

require 'spec_helper'

describe Course::Classifier, type: :model do
  let(:classifier) { create(:classifier) }

  it do
    expect(classifier).to accept_values_for :title,
      'Databases', 'Introduction Courses',
      'Databases 2023', 'Databases_2023',
      'Databases-SQL'
  end

  it do
    expect(classifier).not_to accept_values_for :title,
      nil, ' ', 'Introduction: Courses', 'Databases (2023)'
  end

  it do
    expect(classifier).to accept_values_for :descriptions,
      {en: 'Some description', es: 'Una descripción'},
      {es: 'Sólo descripción en español'},
      {}
  end

  it do
    expect(classifier).to accept_values_for :translations,
      {en: 'English translation', es: 'Traducción español'}
  end

  it do
    expect(classifier).not_to accept_values_for :translations,
      {},
      {es: 'Sólo traducción al español'}
  end
end

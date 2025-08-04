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
      {}
  end

  it do
    expect(classifier).to accept_values_for :translations,
      {en: 'English translation', de: 'Deutsche Übersetzung'}
  end

  it do
    expect(classifier).not_to accept_values_for :translations,
      {de: 'Deutsche Übersetzung'},
      {}
  end
end

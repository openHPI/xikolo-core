# frozen_string_literal: true

require 'spec_helper'

describe Lti::Exercise, '#custom_parameters', type: :model do
  subject(:custom_parameters) { exercise.custom_parameters }

  let(:exercise) { create(:lti_exercise, provider:) }
  let(:provider) { create(:lti_provider) }

  it 'is an empty hash by default' do
    expect(custom_parameters).to eq({})
  end

  it 'turns the user input into a hash' do
    exercise.custom_fields = 'my=own&lti=parameters'

    expect(custom_parameters).to eq({'my' => 'own', 'lti' => 'parameters'})
  end

  it 'inherits parameters from the provider' do
    provider.custom_fields = 'foo=bar&baz=bam'

    expect(custom_parameters).to eq({'foo' => 'bar', 'baz' => 'bam'})
  end

  it 'merges custom parameters from exercise and provider' do
    provider.custom_fields = 'p1=foo&p2=bar'
    exercise.custom_fields = 'e1=baz'

    expect(custom_parameters).to eq({'p1' => 'foo', 'p2' => 'bar', 'e1' => 'baz'})
  end

  it 'lets the exercise override custom parameters from the provider' do
    provider.custom_fields = 'p1=foo&p2=bar'
    exercise.custom_fields = 'e1=baz&p1=NEW'

    expect(custom_parameters).to eq({'p1' => 'NEW', 'p2' => 'bar', 'e1' => 'baz'})
  end

  it 'correctly interprets URL-encoded parameters' do
    exercise.custom_fields = 'special=i%26like%26ampersands'

    expect(custom_parameters).to eq({'special' => 'i&like&ampersands'})
  end
end

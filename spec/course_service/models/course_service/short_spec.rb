# frozen_string_literal: true

require 'spec_helper'

describe CourseService::Short, type: :model do
  subject { short }

  let(:short) { create(:'course_service/short') }

  it { is_expected.to accept_values_for(:title_en, 'Short EN') }
  it { is_expected.to accept_values_for(:title_de, 'Short DE') }
  it { is_expected.to accept_values_for(:title_translations, {'de' => 'Short DE', 'en' => 'Short EN'}) }

  it { is_expected.to accept_values_for(:description_en, 'Short description EN') }
  it { is_expected.to accept_values_for(:description_de, 'Short description DE') }
  it { is_expected.to accept_values_for(:description_translations, {'de' => 'Short description DE', 'en' => 'Short description EN'}) }

  it { is_expected.to accept_values_for(:status, 'preparation', 'active', 'archived') }

  it 'returns the description in the current locale' do
    I18n.with_locale(:de) do
      expect(short.description).to eq 'Short description DE'
    end
    I18n.with_locale(:en) do
      expect(short.description).to eq 'Short description EN'
    end
  end

  it 'returns the title in the current locale' do
    I18n.with_locale(:de) do
      expect(short.title).to eq 'Short DE'
    end
    I18n.with_locale(:en) do
      expect(short.title).to eq 'Short EN'
    end
  end

  it 'does not accept invalid status' do
    expect { short.status = 'invalid' }.to raise_error(ArgumentError)
  end
end

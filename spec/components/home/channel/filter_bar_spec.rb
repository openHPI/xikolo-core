# frozen_string_literal: true

require 'spec_helper'

describe Home::Channel::FilterBar, type: :component do
  subject(:rendered) do
    with_request_url "/channels/#{channel.code}" do
      render_inline described_class.new(user:)
    end
  end

  let(:user) { CurrentUser::AnonymousUser.new(context_id: 'root') }
  let(:channel) { create(:'course_service/channel', code: 'the-channel') }

  before do
    xi_config <<~YML
      course_languages: [de, en]
    YML
  end

  describe 'language filter' do
    it 'shows all available course languages' do
      expect(rendered).to have_select 'Language', text: "All\nEnglish (English)\nGerman (Deutsch)"
    end
  end

  describe 'format filter' do
    context 'with learning units in several formats in the channel' do
      before do
        channel.courses << create(:course, :active, course_format: 'course')
        channel.courses << create(:course, :active, course_format: 'workshop')
      end

      it 'lists formats that have at least one learning unit in the channel' do
        expect(rendered).to have_select 'Format', text: "All\nCourse\nWorkshop"
      end
    end

    context 'with only one format available in the channel' do
      before { channel.courses << create(:course, :active, course_format: 'course') }

      it 'does not show the format filter' do
        expect(rendered).to have_no_select 'Format'
      end
    end

    context 'with formats only on courses outside the channel' do
      before do
        channel.courses << create(:course, :active, course_format: 'course')
        # Belongs to no channel, so its format must not be counted.
        create(:course, :active, course_format: 'workshop')
      end

      it 'only counts learning units within the channel' do
        expect(rendered).to have_no_select 'Format'
      end
    end
  end

  describe '(custom) category filter' do
    before do
      invisible_category = create(:cluster, :invisible, translations: {en: 'Invisible'})
      create(:classifier, cluster: invisible_category, title: 'not_shown', translations: {en: 'Not shown'})
      visible_category = create(:cluster, :visible, translations: {en: 'Topic'})
      create(:classifier, cluster: visible_category, title: 'advanced_learner', translations: {en: 'Advanced'})
    end

    it 'lists the visible categories with localized tags' do
      expect(rendered).to have_select 'Topic', text: "All\nAdvanced"
      expect(rendered).to have_no_select 'Invisible'
    end
  end
end

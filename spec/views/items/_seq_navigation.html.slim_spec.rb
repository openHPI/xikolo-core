# frozen_string_literal: true

require 'spec_helper'

describe 'items/_seq_navigation', type: :view do
  subject(:seq_navigation) { render_view; rendered }

  let(:render_view) { render 'items/seq_navigation', position: presenter }
  let(:presenter) do
    Course::PositionPresenter.new(course:).tap do |p|
      allow(p).to receive(:prev_item).at_least(:once).and_return(prev_item_pres)
      allow(p).to receive(:next_item).at_least(:once).and_return(next_item_pres)
    end
  end
  let(:course) { Xikolo::Course::Course.new course_code: 'test_code' }
  let(:prev_item) { Xikolo::Course::Item.new id: SecureRandom.uuid, title: 'prev text', content_type: 'quiz' }
  let(:prev_item_pres) { QuizItemPresenter.new item: prev_item, course: }
  let(:next_item) { Xikolo::Course::Item.new id: SecureRandom.uuid, title: 'next text', content_type: 'quiz' }
  let(:next_item_pres) { QuizItemPresenter.new item: next_item, course: }

  context 'prev item' do
    it 'contains prev item title, path and icon class' do
      expect(seq_navigation).to include 'prev text'
      expect(seq_navigation).to include "/courses/test_code/items/#{short_uuid(prev_item.id)}"
      expect(seq_navigation).to include 'clipboard-list-check'
    end
  end

  context 'next item' do
    it 'contains next item title, path and icon class' do
      expect(seq_navigation).to include 'next text'
      expect(seq_navigation).to include "/courses/test_code/items/#{short_uuid(next_item.id)}"
      expect(seq_navigation).to include 'clipboard-list-check'
    end
  end
end

# frozen_string_literal: true

require 'spec_helper'

describe Course::PositionPresenter do
  subject(:presenter) { described_class.build(item_resources[1], course, user) }

  let(:user) { Xikolo::Account::User.new id: SecureRandom.uuid }
  let(:course) { Xikolo::Course::Course.new id: SecureRandom.uuid }
  let(:section) { create(:section) }
  let(:section_resource) { build(:'course:section', id: section.id) }
  let(:items) { create_list(:item, 2, :quiz, section_id: section.id) }
  let(:item_resources) { build_list(:'course:item', 2, :quiz, section_id: section.id) }

  before do
    Stub.service(:course, build(:'course:root'))
    Stub.request(:course, :get, '/sections', query: {course_id: course.id})
      .to_return Stub.json([{id: section.id, course_id: course.id}])
    Stub.request(:course, :get, '/items',
      query: {section_id: section.id, published: 'true', state_for: user.id}).to_return Stub.json(item_resources)
  end

  describe '#course' do
    subject { presenter.course }

    it { is_expected.to be_a CourseInfoPresenter }
  end

  describe '#items' do
    subject(:presenter_items) { presenter.items }

    it { is_expected.to be_a Array }

    its([0]) { is_expected.to be_a ItemPresenter }
    its([1]) { is_expected.to be_a ItemPresenter }

    it 'contains the current item as active' do
      expect(presenter_items[0]).not_to be_active
      expect(presenter_items[1]).to be_active
    end
  end
end

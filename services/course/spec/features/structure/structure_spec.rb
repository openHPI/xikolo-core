# frozen_string_literal: true

require 'spec_helper'

describe 'Structure: ...', type: :feature do
  let(:course) { create(:course, :with_content_tree) }

  before do
    week1 = create(:section, course:, title: 'Week 1')
    week2 = create(:section, course:, title: 'Week 2')
    week3 = create(:section, course:, title: 'Week 3')
    week4 = create(:section, course:, title: 'Week 4')

    5.times do |i|
      create(:item, section: week1, title: "1/#{i + 1}")
    end

    3.times do |i|
      create(:item, section: week2, title: "2/#{i + 1}")
    end

    2.times do |i|
      create(:item, section: week3, title: "3/#{i + 1}")
    end

    6.times do |i|
      create(:item, section: week4, title: "4/#{i + 1}")
    end
  end

  it do
    expect(
      Structure::Item.where(course:).joins(:item).pluck('items.title')
    ).to eq %w[1/1 1/2 1/3 1/4 1/5 2/1 2/2 2/3 3/1 3/2 4/1 4/2 4/3 4/4 4/5 4/6]
  end
end

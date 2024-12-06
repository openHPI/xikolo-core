# frozen_string_literal: true

require 'spec_helper'

describe Catalog::Course, '.search_by_text', type: :model do
  subject(:scope) { described_class.search_by_text(query) }

  before do
    skip 'Search reindexing of courses does not yet happen in xi-web'
  end

  let!(:course1) do
    create(:course,
      title: 'Special Course',
      status: 'active',
      abstract: 'Introduction into the trends in development',
      course_code: 'software-development',
      teachers: ['Hans Otto'])
  end

  let!(:course2) do
    create(:course,
      title: 'Blockchain',
      status: 'active',
      abstract: 'another amazing course',
      course_code: 'blockchain-ab',
      teachers: ['Grandmaster Yoda'])
  end

  context 'without match' do
    let(:query) { 'buzzword-driven' }

    it { is_expected.to be_empty }
  end

  context 'with match in title' do
    let(:query) { 'special' }

    it 'returns matching courses' do
      expect(scope).to contain_exactly(an_object_having_attributes(id: course1.id))
    end
  end

  context 'with match in course code' do
    let(:query) { 'software' }

    it 'returns matching courses' do
      expect(scope).to contain_exactly(an_object_having_attributes(id: course1.id))
    end
  end

  context 'with match in abstract' do
    let(:query) { 'amazing' }

    it 'returns matching courses' do
      expect(scope).to contain_exactly(an_object_having_attributes(id: course2.id))
    end
  end

  context 'with match in teacher name' do
    let(:query) { 'hans' }

    it 'returns matching courses' do
      expect(scope).to contain_exactly(an_object_having_attributes(id: course1.id))
    end
  end
end

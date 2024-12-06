# frozen_string_literal: true

require 'spec_helper'

describe Course, '.search_by_text', type: :model do
  subject(:scope) { described_class.search_by_text(query) }

  let!(:teacher) { create(:teacher, name: 'Hans Otto') }
  let!(:teacher2) { create(:teacher, name: 'Peter Koslovski') }
  let!(:teacher3) { create(:teacher, name: 'Hannah Arendt') }

  let!(:course1) do
    create(:course,
      title: 'Special Course',
      status: 'active',
      abstract: 'Introduction into the trends in development',
      course_code: 'software-development',
      alternative_teacher_text: 'MOOC Team',
      teacher_ids: [teacher.id],
      classifiers: [classifier1])
  end

  let!(:course2) do
    create(:course,
      title: 'Blockchain',
      status: 'active',
      abstract: 'another amazing course',
      description: "Hype-driven buzzword bingo, don't take me",
      course_code: 'blockchain101',
      classifiers: [classifier2],
      teacher_ids: [teacher2.id])
  end

  let!(:course3) do
    create(:course,
      title: 'Computer Graphics',
      status: 'active',
      abstract: 'This lecture teaches concepts and techniques for drawing on screens',
      description: 'description',
      course_code: 'drawing',
      classifiers: [classifier3],
      teacher_ids: [teacher3.id])
  end

  let(:cluster1) { create(:cluster, id: 'topic') }
  let(:classifier1) { create(:classifier, title: 'Programming', cluster_id: cluster1.id) }
  let(:classifier2) { create(:classifier, title: 'Finance', cluster_id: cluster1.id) }
  let(:classifier3) { create(:classifier, title: 'DevOps', cluster_id: cluster1.id) }

  before do
    Course.find_each(&:update_search_index)
  end

  context 'without match' do
    let(:query) { 'lorem ipsum' }

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

  context 'with match in description' do
    let(:query) { 'hype' }

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

  context 'with match in alternative teacher text' do
    let(:query) { 'mooc' }

    it 'returns matching courses' do
      expect(scope).to contain_exactly(an_object_having_attributes(id: course1.id))
    end
  end

  context 'with match in classifiers' do
    let(:query) { 'finance' }

    it 'returns matching courses' do
      expect(scope).to contain_exactly(an_object_having_attributes(id: course2.id))
    end
  end

  context 'with match in multiple courses' do
    let(:query) { 'course' }

    it 'returns matching courses' do
      expect(scope).to contain_exactly(an_object_having_attributes(id: course1.id), an_object_having_attributes(id: course2.id))
    end
  end

  context 'with partial match in course code' do
    let(:query) { '101' }

    it 'returns matching courses' do
      expect(scope).to contain_exactly(an_object_having_attributes(id: course2.id))
    end
  end

  context 'with partial match in description' do
    let(:query) { 'buzz' }

    it 'returns matching courses' do
      expect(scope).to contain_exactly(an_object_having_attributes(id: course2.id))
    end
  end

  context 'with partial match in title' do
    let(:query) { 'graph' }

    it 'returns matching courses' do
      expect(scope).to contain_exactly(an_object_having_attributes(id: course3.id))
    end
  end

  context 'with partial match in teacher name' do
    let(:query) { 'Koslov' }

    it 'returns matching courses' do
      expect(scope).to contain_exactly(an_object_having_attributes(id: course2.id))
    end
  end

  context 'with multiple words' do
    let(:query) { 'trends in development' } # abstract: "Introduction into the trends in development"

    it 'returns matching courses' do
      expect(scope).to contain_exactly(an_object_having_attributes(id: course1.id))
    end
  end

  context 'with multiple words in different order' do
    let(:query) { 'development trends' } # abstract: "Introduction into the trends in development"

    it 'returns matching courses' do
      expect(scope).to contain_exactly(an_object_having_attributes(id: course1.id))
    end
  end

  context 'with multiple words each matching a different course' do
    let(:query) { 'special buzzword' } # special -> course1, buzzword -> course2

    it 'matches none of them courses' do
      expect(scope).to be_empty
    end
  end

  context 'with apostrophe in term' do
    let(:query) { "don't me" } # Danger of SQL injection

    it 'returns matching courses' do
      expect(scope).to contain_exactly(an_object_having_attributes(id: course2.id))
    end
  end
end

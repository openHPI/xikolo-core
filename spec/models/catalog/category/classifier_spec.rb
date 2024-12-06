# frozen_string_literal: true

require 'spec_helper'

describe Catalog::Category::Classifier, type: :model do
  subject(:category) { described_class.new cluster_id, classifier_title }

  let(:classifier) { create(:classifier, title: 'Topic A') }
  let(:other_classifier) { create(:classifier, cluster: classifier.cluster) }
  let(:other_cluster_classifier) { create(:classifier) }
  let(:cluster_id) { classifier.cluster_id }
  let(:classifier_title) { 'Topic A' }

  it 'includes active courses' do
    course = create(:course, :active, classifiers: [classifier])

    expect(category.courses).to contain_exactly(an_object_having_attributes(id: course.id))
  end

  it 'does not include courses without classifier' do
    create(:course, :active)

    expect(category.courses).to be_empty
  end

  it 'does not include courses from other classifiers in this cluster' do
    create(:course, :active, classifiers: [other_classifier])

    expect(category.courses).to be_empty
  end

  it 'does not include courses from other clusters' do
    create(:course, :active, classifiers: [other_cluster_classifier])

    expect(category.courses).to be_empty
  end

  it 'includes courses that are *also* assigned to other classifiers' do
    course = create(:course, :active, classifiers: [classifier, other_classifier, other_cluster_classifier])

    expect(category.courses).to contain_exactly(an_object_having_attributes(id: course.id))
  end

  it 'includes courses that should be hidden on the course list' do
    create(:course, :active, title: 'Course not listed', show_on_list: false, classifiers: [classifier])

    expect(category.courses).to contain_exactly(an_object_having_attributes(title: 'Course not listed'))
  end

  it 'does not include hidden courses' do
    create(:course, :active, :hidden, classifiers: [classifier])

    expect(category.courses).to be_empty
  end

  it 'does not include courses in preparation' do
    create(:course, :preparing, classifiers: [classifier])

    expect(category.courses).to be_empty
  end

  it 'includes archived courses' do
    course = create(:course, :archived, classifiers: [classifier])

    expect(category.courses).to contain_exactly(an_object_having_attributes(id: course.id))
  end

  it 'does not include group-restricted courses' do
    create(:course, :active, groups: ['partners'], classifiers: [classifier])

    expect(category.courses).to be_empty
  end

  context 'when there are lots of matching courses' do
    before do
      create_list(:course, 3, :upcoming, classifiers: [classifier])
      create_list(:course, 2, :active, classifiers: [classifier])
      create_list(:course, 1, :archived, classifiers: [classifier])
    end

    it 'shows at most 4 courses, archived ones first' do
      expect(category.courses.length).to eq 4

      expect(category.courses).to match [
        an_object_having_attributes(started?: true, over?: true),
        an_object_having_attributes(started?: true, over?: false),
        an_object_having_attributes(started?: true, over?: false),
        an_object_having_attributes(started?: false),
      ]
    end

    it 'can be configured to a different number of courses' do
      category = described_class.new(cluster_id, classifier_title, max: 6)
      expect(category.courses.length).to eq 6
    end
  end
end

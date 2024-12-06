# frozen_string_literal: true

require 'spec_helper'

describe Catalog::Course, '.by_classifier', type: :model do
  subject(:scope) { described_class.by_classifier(cluster_id, classifier_title) }

  let!(:cluster1) { create(:cluster, id: 'topic') }
  let!(:cluster2) { create(:cluster, id: 'level') }
  let!(:classifier1) { create(:classifier, title: 'Databases', cluster_id: cluster1.id) }
  let!(:classifier2) { create(:classifier, title: 'Expert', cluster_id: cluster2.id) }
  let!(:course1) { create(:course, :active) }
  let!(:course2) { create(:course, :active) }

  before do
    create(:classifier_assignment, course: course1, classifier: classifier1, position: 1)
    create(:classifier_assignment, course: course2, classifier: classifier2, position: 1)
  end

  context 'when cluster and classifier with specified id and title exist' do
    let(:cluster_id) { 'topic' }
    let(:classifier_title) { 'Databases' }

    it 'returns courses with that classifier' do
      expect(scope).to contain_exactly(an_object_having_attributes(id: course1.id))
    end
  end

  context 'when a matching course also has other classifiers' do
    let(:cluster_id) { 'level' }
    let(:classifier_title) { 'Expert' }

    before do
      create(:classifier_assignment, course: course1, classifier: classifier2, position: 2)
    end

    it 'still returns courses with the requested classifier' do
      expect(scope).to contain_exactly(an_object_having_attributes(id: course1.id), an_object_having_attributes(id: course2.id))
    end
  end

  context 'when there is no corresponding cluster and classifier' do
    let(:cluster_id) { 'fruits' }
    let(:classifier_title) { 'Bananas' }

    it 'returns no courses' do
      expect(scope).to be_empty
    end
  end
end

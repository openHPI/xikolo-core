# frozen_string_literal: true

require 'spec_helper'

describe CourseService::Cluster do
  let(:cluster) { create(:'course_service/cluster') }

  describe '(validations)' do
    it { expect(cluster).to accept_values_for :id, 'mycluster', 'mycluster-1', 'my-cluster', 'my_cluster' }
    it { expect(cluster).not_to accept_values_for :id, nil, ' ', 'my cluster' }

    it { expect(cluster).to accept_values_for :sort_mode, 'automatic', 'manual' }
    it { expect(cluster).not_to accept_values_for :sort_mode, nil, '', 'invalid' }

    it do
      create(:'course_service/cluster', id: 'mycluster')
      expect(cluster).not_to accept_values_for :id, 'MyCluster'
    end

    it do
      expect(cluster).to accept_values_for :translations,
        {en: 'English translation', de: 'Deutsche Übersetzung'}
    end

    it do
      expect(cluster).not_to accept_values_for :translations,
        {de: 'Deutsche Übersetzung'},
        {}
    end
  end

  describe 'deletion' do
    let(:cluster) { create(:'course_service/cluster') }

    before do
      create_list(:'course_service/classifier', 3, cluster:)

      # And a classifier in another cluster that should not be deleted
      create(:'course_service/classifier', cluster: create(:'course_service/cluster'))
    end

    it 'deletes all classifiers' do
      expect { cluster.destroy }.to change(CourseService::Classifier, :count).from(4).to(1)
    end
  end
end

# frozen_string_literal: true

require 'spec_helper'

describe Course::Cluster, type: :model do
  let(:cluster) { create(:cluster) }

  describe '(validations)' do
    it { expect(cluster).to accept_values_for :id, 'mycluster', 'mycluster-1', 'my-cluster', 'my_cluster' }
    it { expect(cluster).not_to accept_values_for :id, nil, ' ', 'my cluster' }

    it { expect(cluster).to accept_values_for :sort_mode, 'automatic', 'manual' }
    it { expect(cluster).not_to accept_values_for :sort_mode, nil, '', 'invalid' }

    it do
      create(:cluster, id: 'mycluster')
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

  describe '(classifier order)' do
    context "sort the cluster's classifiers automatically" do
      let(:cluster) { create(:cluster, :order_automatic) }

      before do
        create(:classifier, title: 'C', translations: {en: 'second'}, position: 1, cluster:)
        create(:classifier, title: 'A', translations: {en: 'third'}, position: 2, cluster:)
        create(:classifier, title: 'B', translations: {en: 'first'}, position: 3, cluster:)
      end

      it 'lists classifiers alphabetically by translation' do
        expect(cluster.classifiers.pluck(:title)).to eq %w[B C A]
      end

      context 'with missing requested translation' do
        before do
          create(:classifier, title: 'E', translations: {en: 'fifth', de: 'fünfte'}, position: 4, cluster:)
          create(:classifier, title: 'D', translations: {en: 'fourth', de: 'vierte'}, position: 5, cluster:)
        end

        it 'lists classifiers alphabetically by available translations' do
          I18n.with_locale(:de) do
            expect(cluster.classifiers.pluck(:title)).to eq %w[B E C A D]
          end
        end
      end
    end

    context "sort the cluster's classifiers manually" do
      let(:cluster) { create(:cluster, :order_manual) }

      before do
        create(:classifier, title: 'C', translations: {en: 'second'}, position: 1, cluster:)
        create(:classifier, title: 'A', translations: {en: 'first'}, position: 2, cluster:)
        create(:classifier, title: 'B', translations: {en: 'third'}, position: 3, cluster:)
      end

      it 'lists classifiers by position' do
        expect(cluster.classifiers.pluck(:title)).to eq %w[C A B]
      end
    end
  end

  describe '(deletion)' do
    before do
      create_list(:classifier, 3, cluster:)

      # And a classifier in another cluster that should not be deleted
      create(:classifier)
    end

    it 'deletes all classifiers' do
      expect { cluster.destroy! }.to change(Course::Classifier, :count).from(4).to(1)
    end
  end
end

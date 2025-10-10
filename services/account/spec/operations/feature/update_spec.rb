# frozen_string_literal: true

require 'spec_helper'

describe Feature::Update, type: :operation do
  subject(:operation) { described_class.new(owner, context) }

  let(:owner) { create(:'account_service/group') }
  let(:context) { Context.root }
  let(:features) do
    {
      'feature.a' => 1,
      'feature.b' => 2,
    }
  end

  it 'creates new features' do
    expect { operation.call(features) }
      .to change(Feature, :count).from(0).to(2)

    Feature.order(:name).first.tap do |a|
      expect(a.name).to eq 'feature.a'
      expect(a.value).to eq '1'
      expect(a.owner).to eq owner
      expect(a.context).to eq context
    end

    Feature.order(:name).last.tap do |a|
      expect(a.name).to eq 'feature.b'
      expect(a.value).to eq '2'
      expect(a.owner).to eq owner
      expect(a.context).to eq context
    end
  end

  context 'with one existing record' do
    let!(:existing) do
      create(:'account_service/feature', owner:, context:, name: 'feature.a', value: 0)
    end

    it 'updates existing feature' do
      expect { operation.call(features) }
        .to change { existing.reload.value }.from('0').to('1')
    end

    it 'creates new feature' do
      expect { operation.call(features) }
        .to change(Feature, :count).from(1).to(2)

      Feature.order(:name).last.tap do |a|
        expect(a.name).to eq 'feature.b'
        expect(a.value).to eq '2'
        expect(a.owner).to eq owner
        expect(a.context).to eq context
      end
    end
  end
end

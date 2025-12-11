# frozen_string_literal: true

require 'spec_helper'

describe QuizService::QuizSubmissionSnapshot, type: :model do
  subject(:snapshot) do
    create(:'quiz_service/quiz_submission_snapshot')
  end

  let(:params) { {} }

  it { is_expected.to be_valid }

  context 'with !ruby/hash:ActionController::Parameters' do
    before do
      # This is a YAML serialized `ActionController::Parameters` object dumped
      # as a string (!) serialized in YAML. Yes, double YAML encoding.
      update_raw_snapshot_data snapshot, <<~YAML
        --- |
          --- !ruby/hash:ActionController::Parameters
          309239ad-ec98-4337-8bb9-6a9f85b0eaf5: cae5153f-1068-4051-8ec6-99b45e225862
          7137cdec-7a76-4eb1-9bca-6066ce78088f:
          - e45f2fdb-f606-4659-acfe-19aecfbbed2f
          4fc6cc68-3432-4da1-81c6-b88c0bbbfac3: d1a2727f-b0bf-41ce-a7dc-df98776739d9
          9e649e2c-e095-4b83-8ac8-0d89f508afa0: d50ddfc3-9c14-4f7e-9640-403620de5edd
      YAML
    end

    it 'can succesfully decode' do
      expect(snapshot.data).to be_a Hash
      expect(snapshot.data).to eq \
        '309239ad-ec98-4337-8bb9-6a9f85b0eaf5' => 'cae5153f-1068-4051-8ec6-99b45e225862',
        '7137cdec-7a76-4eb1-9bca-6066ce78088f' => ['e45f2fdb-f606-4659-acfe-19aecfbbed2f'],
        '4fc6cc68-3432-4da1-81c6-b88c0bbbfac3' => 'd1a2727f-b0bf-41ce-a7dc-df98776739d9',
        '9e649e2c-e095-4b83-8ac8-0d89f508afa0' => 'd50ddfc3-9c14-4f7e-9640-403620de5edd'
    end
  end

  context 'with !ruby/hash:ActiveSupport::HashWithIndifferentAccess' do
    before do
      # This is a YAML serialized `ActionController::Parameters` object dumped
      # as a string (!) serialized in YAML. Yes, double YAML encoding.
      update_raw_snapshot_data snapshot, <<~YAML
        --- |
          --- !ruby/hash:ActiveSupport::HashWithIndifferentAccess
          309239ad-ec98-4337-8bb9-6a9f85b0eaf5: cae5153f-1068-4051-8ec6-99b45e225862
          7137cdec-7a76-4eb1-9bca-6066ce78088f:
          - e45f2fdb-f606-4659-acfe-19aecfbbed2f
          4fc6cc68-3432-4da1-81c6-b88c0bbbfac3: d1a2727f-b0bf-41ce-a7dc-df98776739d9
          9e649e2c-e095-4b83-8ac8-0d89f508afa0: d50ddfc3-9c14-4f7e-9640-403620de5edd
      YAML
    end

    it 'can succesfully decode' do
      expect(snapshot.data).to be_a Hash
      expect(snapshot.data).to eq \
        '309239ad-ec98-4337-8bb9-6a9f85b0eaf5' => 'cae5153f-1068-4051-8ec6-99b45e225862',
        '7137cdec-7a76-4eb1-9bca-6066ce78088f' => ['e45f2fdb-f606-4659-acfe-19aecfbbed2f'],
        '4fc6cc68-3432-4da1-81c6-b88c0bbbfac3' => 'd1a2727f-b0bf-41ce-a7dc-df98776739d9',
        '9e649e2c-e095-4b83-8ac8-0d89f508afa0' => 'd50ddfc3-9c14-4f7e-9640-403620de5edd'
    end
  end

  context 'with !ruby/hash-with-ivars:ActionController::Parameters' do
    before do
      # Taken from real data
      update_raw_snapshot_data snapshot, <<~YAML
        --- |
          --- !ruby/hash-with-ivars:ActionController::Parameters
          elements:
            a8c22171-ef3b-4007-bedc-c8d8d28d7ae6: &1
            - a37dae25-b04e-490a-b460-5274225b4fd6
            - 62a0dee6-a4a6-4d38-89c2-1c2f5f73c5be
            a90c7341-3070-47f7-a33e-6b5246c4d178: e7b5de6f-1d72-4834-be2a-13875416ee11
            a9b04e31-ff37-4a35-87fe-81589e66a72d: 207d52c1-10a9-4c09-9a96-5c3b042e7967
            e8cb8ec6-e9a7-46ac-9d1a-3dca2392a39e: &2
            - 9ed7fd11-f106-46c6-82c4-d6ee7be88144
          ivars:
            :@permitted: false
            :@converted_arrays: !ruby/object:Set
              hash:
                *1: true
                *2: true
      YAML
    end

    it 'can succesfully decode' do
      expect(snapshot.data).to be_a Hash
      expect(snapshot.data).to eq \
        'a8c22171-ef3b-4007-bedc-c8d8d28d7ae6' => %w[
          a37dae25-b04e-490a-b460-5274225b4fd6
          62a0dee6-a4a6-4d38-89c2-1c2f5f73c5be
        ],
        'a90c7341-3070-47f7-a33e-6b5246c4d178' => 'e7b5de6f-1d72-4834-be2a-13875416ee11',
        'a9b04e31-ff37-4a35-87fe-81589e66a72d' => '207d52c1-10a9-4c09-9a96-5c3b042e7967',
        'e8cb8ec6-e9a7-46ac-9d1a-3dca2392a39e' => ['9ed7fd11-f106-46c6-82c4-d6ee7be88144']
    end
  end

  def update_raw_snapshot_data(snapshot, data)
    ActiveRecord::Base.connection.tap do |conn|
      # Do *not* use `#squish` here. The `data` value will contain newlines that
      # would get striped by squish.
      #
      # rubocop:disable Rails/SquishedSQLHeredocs
      conn.execute <<~SQL
        UPDATE quiz_submission_snapshots
        SET data = #{conn.quote(data)}
        WHERE id = #{conn.quote(snapshot.id)}
      SQL
      # rubocop:enable Rails/SquishedSQLHeredocs
    end

    snapshot.reload
  end
end

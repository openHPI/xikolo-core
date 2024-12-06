# frozen_string_literal: true

module UpdateRawSnapshotData
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

RSpec.configure do |config|
  config.include UpdateRawSnapshotData
end

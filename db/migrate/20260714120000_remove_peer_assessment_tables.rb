# frozen_string_literal: true

class RemovePeerAssessmentTables < ActiveRecord::Migration[7.2]
  def up
    drop_table :conflicts, if_exists: true
    drop_table :participants, if_exists: true
    drop_table :peer_assessment_files, if_exists: true
    drop_table :peer_assessment_groups, if_exists: true
    drop_table :peer_assessments, if_exists: true
    drop_table :resource_pools, if_exists: true
    drop_table :rubrics, if_exists: true
    drop_table :shared_submissions, if_exists: true
    drop_table :steps, if_exists: true
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end

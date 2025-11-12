# frozen_string_literal: true

module PinboardService
class AbuseReport < ApplicationRecord # rubocop:disable Layout/IndentationWidth
  self.table_name = :abuse_reports

  belongs_to :reportable, polymorphic: true

  validates :reportable_type, :user_id, presence: true
  validates :user_id, uniqueness: {scope: :reportable_id}

  scope :open_reportables, lambda {
    questions = open_reportables_by_class(Question).to_sql
    answers = open_reportables_by_class(Answer).to_sql
    comments = open_reportables_by_class(Comment).to_sql

    AbuseReport.default_scoped.from(
      "(#{questions} UNION #{answers} UNION #{comments}) AS abuse_reports"
    )
  }

  scope :open_reportables_by_class, lambda {|reportable_class|
    table = reportable_class.table_name
    joins("JOIN #{table} r ON r.id=abuse_reports.reportable_id")
      .where(reportable_type: reportable_class.name)
      .where("r.workflow_state='auto_blocked' OR r.workflow_state='reported'")
  }

  after_save do
    reportable.report!
  end

  def question_title
    reportable.question_title
  end
end
end

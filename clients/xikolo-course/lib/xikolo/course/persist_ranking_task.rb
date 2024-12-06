# frozen_string_literal: true

module Xikolo::Course
  class PersistRankingTask < Acfs::SingletonResource
    service Xikolo::Course::Client, path: '/courses/:course_id/persist_ranking_task'
    attribute :course_id, :uuid
  end
end

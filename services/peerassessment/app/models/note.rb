# frozen_string_literal: true

#
# Notes created by the teaching staff for decisions they made in conflict
# reconciliations, re-gradings, etc. A polymorphic assoc has been chosen to
# avoid a join table or a lot of empty arrays on other models - which would also
# limit the uses of notes later on.
#
class Note < ApplicationRecord
  belongs_to :subject, polymorphic: true
  default_scope { order('created_at ASC') }
end

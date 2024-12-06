# frozen_string_literal: true

class CalendarEvent < ApplicationRecord
  CATEGORIES = %w[available unavailable meeting milestone other].freeze

  belongs_to :collab_space, optional: true
  validates :user_id, :title, :start_time, :end_time, :collab_space,
    presence: {message: 'required'}
  validates :category,
    presence: {message: 'required'},
    inclusion: {in: CATEGORIES, message: 'unknown'}
end

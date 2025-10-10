# frozen_string_literal: true

class Cluster < ApplicationRecord
  self.table_name = :clusters

  has_many :classifiers, -> { order(:title) },
    inverse_of: :cluster,
    dependent: :delete_all

  validates :id,
    presence: true,
    format: {with: /\A[\w-]+\z/, message: 'invalid_format'},
    uniqueness: {case_sensitive: false, message: 'not_unique'}
  validates :sort_mode,
    presence: true,
    inclusion: %w[automatic manual]
  validate do
    if translations[Xikolo.config.locales['default']].blank?
      errors.add :translations, :missing
    end
  end
end

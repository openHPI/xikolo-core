# frozen_string_literal: true

class Treatment < ApplicationRecord
  has_many :consents, dependent: :destroy

  after_create do
    group = Group.create!(
      name: "treatment.#{name}",
      description: "Users consenting to #{name}"
    )

    Feature.create!(
      name: "treatment.#{name}",
      value: true,
      owner: group,
      context: Context.root
    )
  end

  validates :name,
    uniqueness: {message: 'exists'},
    format: {with: /\A[\w\d]+\z/, message: 'invalid'}

  CONSENT_MANAGER_KEYS = %w[type consent_url].sort.freeze
  validate do
    next if consent_manager.blank?

    unless (consent_manager.keys.sort == CONSENT_MANAGER_KEYS) &&
           consent_manager['type'].present?
      errors.add :consent_manager, :invalid
    end
  end

  class << self
    def lookup!(id: nil, name: nil)
      scope = self
      scope = scope.where(id:) if id.present?
      scope = scope.where(name:) if name.present?
      scope.take!
    end
  end

  def group
    @group ||= Group.find_by(name: "treatment.#{name}")
  end
end

# frozen_string_literal: true

class Document < ApplicationRecord
  self.table_name = :documents

  validates :title, :description, presence: true
  validates :title, uniqueness: {conditions: -> { not_deleted }}
  has_and_belongs_to_many :courses, -> { not_deleted }

  has_many :documents_items, dependent: :delete_all
  has_many :items, through: :documents_items

  has_many :localizations, -> { not_deleted },
    class_name: 'DocumentLocalization',
    inverse_of: :document

  default_scope { order('documents.title ASC') }
  scope :not_deleted, -> { where(deleted: false) }
  scope :tagged_with, ->(tag) { where '? = ANY (tags)', tag }

  after_create do
    Msgr.publish(decorate.as_event, to: 'xikolo.course.document.create')
    update_courses
  end
  after_update do
    update_courses
    Msgr.publish(decorate.as_event, to: 'xikolo.course.document.update')
  end

  def soft_delete
    ActiveRecord::Base.transaction do
      localizations.each(&:soft_delete)
      update! deleted: true
      Msgr.publish(decorate.as_event, to: 'xikolo.course.document.destroy')
    end
    self
  end

  def self.all_tags
    Document.unscoped.from('(SELECT unnest(tags) AS tag FROM documents) tags')
      .group('tag')
      .order(Arel.sql('count(*) DESC'))
      .pluck('tag')
  end

  private

  # add courses of the items to the course list
  def update_courses
    self.courses |= items.map {|item| item.section.course }
  end
end

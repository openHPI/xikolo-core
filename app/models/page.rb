# frozen_string_literal: true

class Page < ApplicationRecord
  attribute :text, Xikolo::S3::Markup.new(
    uploads: {
      purpose: 'helpdesk_page_file',
      content_type: %w[image/* application/pdf],
    }
  )

  # rubocop:disable Rails/HasManyOrHasOneDependent
  has_many :translations, class_name: 'Page', foreign_key: 'name', inverse_of: false, primary_key: :name
  has_many :other_translations, ->(page) { where.not(locale: page.locale) },
    class_name: 'Page', foreign_key: 'name', inverse_of: false, primary_key: :name
  # rubocop:enable all

  validates :name, :title, :text, presence: true
  validates :locale, format: {with: /\A[a-z]{2,3}(-[a-z]{4})?(-[a-z]{2})?\z/i}

  class << self
    def preferred_locales(*locales)
      raise 'At least one locale needed' if locales.empty?

      locales.uniq!

      order_clause = locales.each_index.reduce('') do |sql, index|
        "#{sql} WHEN ? THEN #{index}"
      end
      order_clause = "CASE locale #{order_clause} ELSE #{locales.count} END"

      reorder([Arel.sql(order_clause), *locales], :created_at)
    end
  end
end

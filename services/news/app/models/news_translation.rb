# frozen_string_literal: true

class NewsTranslation < ApplicationRecord
  validates :title, :text, presence: true
  validates :locale, uniqueness: {scope: :news_id}

  belongs_to :news

  def teaser
    return super if super.present?

    text.lines.slice(0, 5).join
  end
end

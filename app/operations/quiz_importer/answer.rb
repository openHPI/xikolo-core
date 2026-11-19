# frozen_string_literal: true

module QuizImporter
  class Answer
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :type, :string
    attribute :text, :string
    attribute :correct, :boolean
    attribute :explanation, :string, default: ''

    validates :text, presence: true
    validates :type, inclusion: {in: %w[TextAnswer FreeTextAnswer]}
    validates :correct, inclusion: {in: [true, false]}
  end
end

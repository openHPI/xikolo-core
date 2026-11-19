# frozen_string_literal: true

module QuizImporter
  class Question
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :text, :string
    attribute :type, :string
    attribute :points, :integer
    attribute :explanation, :string, default: ''
    attribute :exclude_from_recap, :boolean, default: false
    attribute :shuffle_answers, :boolean, default: true

    validates :text, presence: true
    validates :type, inclusion: {in: %w[MultipleChoice MultipleAnswer FreeText]}
    validates :points, numericality: {only_integer: true, greater_than_or_equal_to: 0}
    validates :exclude_from_recap, inclusion: {in: [true, false]}
    validates :shuffle_answers, inclusion: {in: [true, false]}

    def initialize(attrs = {})
      super
      @answers = []
    end

    def add_answer(answer)
      @answers << answer
    end

    attr_reader :answers
  end
end

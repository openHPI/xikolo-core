# frozen_string_literal: true

module QuizImporter
  class Quiz
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :name, :string
    attribute :section, :integer
    attribute :subsection, :integer
    attribute :type, :string
    attribute :instructions, :string, default: ''
    attribute :attempts, :integer
    attribute :time, :integer
    attribute :graded, :boolean, default: false
    attribute :bonus, :boolean, default: false
    attribute :final_exam, :boolean, default: false
    attribute :survey, :boolean, default: false
    attribute :external_ref, :string

    validates :name, presence: true
    validates :section, numericality: {only_integer: true, greater_than_or_equal_to: 0}
    validates :subsection, numericality: {only_integer: true, greater_than_or_equal_to: 0}, allow_nil: true
    validates :type, inclusion: {in: ['selftest', 'weekly assignment', 'bonus', 'final exam', 'survey']}
    validates :attempts, numericality: {only_integer: true, greater_than_or_equal_to: 0}
    validates :time, numericality: {only_integer: true, greater_than_or_equal_to: 0}

    def initialize(attrs = {})
      super
      @questions = []
    end

    def add_question(question)
      @questions << question
    end

    attr_reader :questions
  end
end

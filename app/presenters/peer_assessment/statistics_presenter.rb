# frozen_string_literal: true

class PeerAssessment::StatisticsPresenter < Presenter
  def_delegators :statistic,
    :available_submissions,
    :finished_reviews,
    :nominations,
    :required_reviews,
    :submitted_submissions

  attr_accessor :statistic

  def self.create(statistic)
    new statistic:
  end

  def reviews_left
    [required_reviews - finished_reviews, 0].max
  end

  def additional_review_possible?
    finished_reviews < required_reviews * 2
  end

  ### Student-facing training process ###

  def sample_number
    "#{finished_reviews + 1} / #{required_reviews}"
  end

  def complete?
    reviews_left <= 0
  end

  ### Training sample creation (admin) ###

  def train_sample_bar
    "#{finished_reviews} / #{required_reviews}"
  end

  def train_sample_percentage
    [(finished_reviews.to_f / required_reviews) * 100, 100].min
  end

  def train_sample_percentage_undone
    100 - train_sample_percentage
  end

  def training_available?
    complete?
  end
end

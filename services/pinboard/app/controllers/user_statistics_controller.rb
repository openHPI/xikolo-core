# frozen_string_literal: true

class UserStatisticsController < ApplicationController
  responders Responders::DecorateResponder,
    Responders::HttpCacheResponder,
    Responders::PaginateResponder

  respond_to :json

  def show
    user_id = params[:user_id]
    respond_with \
      accepted_answers: accepted_answers(user_id),
      vote_values_given: vote_values_given(user_id),
      vote_values_received: vote_values_received(user_id)
  end

  # number of accepted answers of a specific user
  def accepted_answers(user_id)
    Question.joins(:accepted_answer)
      .where(answers: {user_id:})
      .count
  end

  # sum of votes given by a user
  def vote_values_given(user_id)
    Vote.where(user_id:).sum(:value)
  end

  # sum of votes received by a user
  def vote_values_received(user_id)
    query = [%{
      SELECT SUM(value) FROM (
        ( SELECT value
          FROM votes v, questions q
          WHERE q.id = v.votable_id
          AND q.user_id = ?  )
        UNION ALL
        ( SELECT value
          FROM votes v, answers a
          WHERE a.id = v.votable_id
          AND a.user_id = ? )
      ) AS temp
    }, user_id, user_id]
    Vote.find_by_sql(query).first.sum
  end
end

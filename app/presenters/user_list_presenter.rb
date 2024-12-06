# frozen_string_literal: true

class UserListPresenter
  def initialize(users_promise)
    @users_promise = users_promise
  end

  def each
    all.each do |user|
      yield UserPresenter.new user
    end
  end

  def pagination
    RestifyPaginationCollection.new all
  end

  private

  def all
    @users_promise.value!
  end
end

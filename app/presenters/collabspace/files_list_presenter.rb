# frozen_string_literal: true

class Collabspace::FilesListPresenter
  extend Forwardable

  def initialize(files, current_user, collabspace)
    @files = files
    @current_user = current_user
    @collabspace = collabspace
  end

  def_delegators :all, :each, :any?

  def pagination
    RestifyPaginationCollection.new @files
  end

  private

  def all
    @all ||= @files.map do |file|
      Collabspace::FilePresenter.new file, @current_user, @collabspace
    end
  end
end

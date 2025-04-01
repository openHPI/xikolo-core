# frozen_string_literal: true

class DocumentsListPresenter < PrivatePresenter
  def_delegators :@documents, :empty?

  def self.build(documents, courses, tags, params, helpers)
    new(
      documents:,
      courses:,
      tags:,
      params:,
      helpers:
    )
  end

  def initialize(*)
    super

    @languages = @documents.flat_map do |document|
      document['localizations'].pluck('language')
    end.uniq
  end

  def each
    @documents.each do |document|
      yield DocumentPresenter.new(document:, courses: @courses)
    end
  end

  def filters?
    !filters.empty?
  end

  def filtered?
    !@params.empty?
  end

  def tag_list
    @tags.to_h {|t| [t, t] }
  end

  def language_list
    @languages.to_h {|l| [l, l] }
  end

  def total_pages
    @documents.response.headers['X_TOTAL_PAGES'].to_i
  end

  def current_page
    @documents.response.headers['X_CURRENT_PAGE'].to_i
  end

  def filters
    @filters ||= [].tap do |filters|
      unless @languages.empty?
        filters << DocumentListFilter.new(
          'language', 'Languages', @params['language'], language_list, @helpers
        )
      end

      unless @tags.empty?
        filters << DocumentListFilter.new(
          'tag', 'Tags', @params['tag'], tag_list, @helpers
        )
      end
    end
  end

  class DocumentPresenter < PrivatePresenter
    def_restify_delegators :@document, :id, :title, :description, :tags

    def courses
      @document.fetch('course_ids').map do |course_id|
        course = @courses.find {|c| c['id'] == course_id }
        course ? course['title'] : course_id
      end
    end

    def localizations
      @document['localizations'].map do |loc|
        Localization.new(
          I18nData.languages(I18n.locale).fetch(loc.fetch('language').upcase),
          loc.fetch('file_url')
        )
      end
    end

    Localization = Struct.new(:title, :file_url)
  end

  class DocumentListFilter
    def initialize(key, name, current_value, values, helpers)
      @key = key
      @name = name
      @current_value = current_value
      @values = values
      @helpers = helpers
    end

    attr_reader :values

    def label
      if @current_value
        title = @values[@current_value]
        "#{@name}: #{title}"
      else
        @name
      end
    end

    def each_value
      old_params = @helpers.params.permit(:language, :tag)
      yield 'All', @helpers.url_for(old_params.except(@key)), @current_value.nil?

      @values = @values.sort_by {|_key, value| value }.to_h
      @values.each do |key, value|
        yield value, @helpers.url_for(old_params.merge(@key => key)), key == @current_value
      end
    end
  end
end

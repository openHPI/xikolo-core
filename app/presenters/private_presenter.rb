# frozen_string_literal: true

class PrivatePresenter
  extend Forwardable
  extend RestifyForwardable

  attr_accessor :preloader

  def initialize(params)
    self.preloader = Preloading::Preloader.new(false)

    params&.each_pair do |attribute, value|
      instance_variable_set :"@#{attribute}", value
    end
  end

  def self.inherited(cls)
    super

    # Load the Preloading module into each child class so that the
    # `#build_collection` class method is available.
    cls.extend(Preloading)
  end

  module Preloading
    # Build a collection of presenters based on a collection of same
    # resources, for example, courses. The collection is linked to each
    # presenters preloader, to enable preloading associated resources
    # for each element.
    #
    # Each element from the collection will be passed to `#build` along
    # with all extra arguments. If a block is given, it will be called
    # instead of `#build` and must return a presenter object.
    #
    def build_collection(collection, *, **)
      preloader = Preloading::Preloader.new(collection)

      collection.map do |element|
        if block_given?
          yield(element, *, **)
        else
          build(element, *, **)
        end.tap do |presenter|
          presenter.preloader = preloader
        end
      end
    end

    class Preloader
      def initialize(collection)
        @collection = collection
        @cache = {}
      end

      # Preload an associated resource
      #
      # Example:
      #
      #      preloader.load(:cache_key, @course['id'], [@course]) do |collection|
      #        Course::Visual
      #          .where(course_id: collection.pluck('id'))
      #          .group_by(&:course_id)
      #          .transform_values(&:first)
      #      end
      #
      # The `name` is used to cache the preloaded records. Different
      # names allow preloading different things. `value` will be used to
      # look up the current record. The `default` parameter specified a
      # default collection passed to the preloaded if no collection is
      # configured otherwise.
      #
      # The block must return a Hash with key-value pairs that map the
      # lookup value with a result object.
      #
      def load(name, value, default = [])
        @cache.fetch(name) do
          yield(@collection || default).tap do |records|
            @cache[name] = records
          end
        end[value]
      end

      def clear
        @cache.clear
      end
    end
  end
end

# frozen_string_literal: true

module AccountService
class Feature::Update < ApplicationOperation # rubocop:disable Layout/IndentationWidth
  include Facets::Transaction

  attr_reader :owner, :context

  def initialize(owner, context)
    super()

    @owner = owner
    @context = context
  end

  def call(features)
    features.each_pair do |name, value|
      next if inherited_features.include? name

      if (feature = scope.resolve(name).take)
        if value.nil?
          feature.destroy!
        else
          feature.update! value:
        end
      else
        scope.create! name:, value:
      end
    end
  end

  private

  def inherited_features
    @inherited_features ||= if context.parent
                              Feature.lookup(owner:, context: context.parent).pluck :name
                            else
                              []
                            end
  end

  def scope
    @scope ||= Feature.where owner:, context:
  end
end
end

# frozen_string_literal: true

module AccountService
class Feature < ApplicationRecord # rubocop:disable Layout/IndentationWidth
  self.table_name = 'flippers'

  validates :name, :value, :context, presence: {message: 'required'}
  validates :name, uniqueness: {
    case_sensitive: false, scope: %i[owner_id context_id], message: 'invalid'
  }

  attribute :new, :boolean, default: false

  belongs_to :owner, polymorphic: true
  belongs_to :context

  class << self
    def resolve(name)
      where name: name.to_s.downcase
    end

    def lookup(owner:, context:)
      contexts = Context.resolve(context).ascent.to_a

      scopes = []
      scopes << Feature.where(owner:)
      scopes << Feature.where(owner: Group.for(owner))

      where(context: contexts).merge(scopes.reduce(&:or))
    end

    # Ensures a feature with a given name exists in a context.
    #
    # If a new feature is created the pseudo attribute `new` will be set
    # to `true`. If a feature already exist a given value will *not* be
    # updated.
    #
    # @param name [String]
    #   Feature name.
    #
    # @param context [Context]
    #   Context the feature should be applied to.
    #
    # @param value [String|Object]
    #   Feature value. Defaults to `true`. Should be rarely used.
    #
    #   The value will *not* be updated if the feature already exists.
    #
    # @option kwargs owner [User|Group]
    #   Optional owner for the feature. Can be given through the scope
    #   when using `ensure_exists!` as a scope method.
    #
    # @example Ensure a feature exists and set a proper status code if new
    #   feature = Feature.ensure_exists! \
    #               name: 'feature_name',
    #               owner: current_user,
    #               context: Context.root
    #
    #   if feature.new?
    #     render something, status: :created
    #   else
    #     render something, status: :ok
    #   end
    #
    # @example Get owner from scope
    #   current_user.features.ensure_exists! \
    #               name: 'feature_name',
    #               context: Context.root
    #
    def ensure_exists!(name:, context:, value: true, **kwargs)
      where(name:, context:, **kwargs.slice(:owner))
        .first_or_create!(value:, new: true)
    rescue ActiveRecord::RecordNotUnique
      retry
    end
  end

  def name=(name)
    super(name.to_s.downcase)
  end
end
end

# frozen_string_literal: true

class Factory
  class << self
    def create(type, attrs = {})
      factories.fetch(type).call attrs
    end

    def create_list(type, count, attrs = {})
      list = []

      Integer(count).times do
        list << create(type, attrs)
      end

      list
    end

    def factories
      @factories ||= {}
    end

    def define(type, &)
      factories[type] = new(&)
    end

    def seq
      @index ||= 0
      @index += 1
    end
  end

  def initialize(&)
    instance_eval(&)
  end

  def field(name, value)
    fields[name] = value
  end

  def fields
    @fields ||= {}
  end

  def call(attrs)
    object = {}

    fields.each do |name, value|
      value = attrs.fetch(name, value)

      object[name] = case value
                       when Proc
                         value.call(object)
                       else
                         value
                     end
    end

    object.merge!(attrs)
    object
  end

  def seq
    proc {|o| yield Factory.seq, o }
  end
end

Factory.define :user do
  field :password, 'secret123'
  field(:full_name, seq {|i| "John Smith#{i}" })
  field :email, ->(user) { "#{user[:full_name].parameterize(separator: '.')}@text.xikolo.de" }
  field :confirmed, true
  field :admin, false
end

Factory.define :forum_topic do
  field(:title, seq {|i| "A Very (VERY) important question (the #{i}th)" })
  field :text, 'I have no idea what to ask.'
end

Factory.define :authorization do
  field :user_id, SecureRandom.uuid
  field :provider, 'saml'
  field :uid, 'P123456'
  field :info, {}
end

Factory.define :treatment do
  field :name, 'marketing'
  field :required, false
end

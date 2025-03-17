# frozen_string_literal: true

require 'active_support/core_ext/hash/keys'

module Xikolo::Common::Auth::CurrentUser
  def self.from_session(session)
    # We check for false explicitly here in case no user is embedded
    # (in which case `dig` would return `nil`, which is also falsy).
    if session.dig('user', 'anonymous') === false # rubocop:disable Style/CaseEquality
      Authenticated.new session
    else
      Anonymous.new session
    end
  end

  class Base
    def initialize(session)
      @session = session
      @user = session['user'].to_h
      @features = session['features'].to_h
      @permissions = session['permissions'].to_a
      @permission_map = {}
    end

    def session_id
      @session['id']
    end

    def interrupts
      @session['interrupts'] || []
    end

    # @deprecated
    def interrupt_session?
      interrupts.any?
    end
    alias interrupt interrupt_session?
    alias interrupt? interrupt_session?

    # Permission Checks
    # =================
    def allowed?(permission, context: nil)
      permissions_for(context).include? permission.to_s
    end

    def allowed_any?(*permissions, context: nil)
      !!permissions_for(context).intersect?(permissions.map(&:to_s))
    end

    # Feature Flipper
    # ===============
    def feature(name)
      @features[name.to_s]
    end

    def feature_set?(name)
      @features.key?(name.to_s)
    end
    alias feature? feature_set?

    # User Attributes
    # ===============
    def id
      @session['user_id']
    end

    def affiliated?
      @user['affiliated'] || false
    end

    def affiliation
      @user['affiliation']
    end

    def instrumented?
      @session['masqueraded'] || false
    end
    alias masqueraded? instrumented?

    def name
      @user['name']
    end

    def full_name
      @user['full_name']
    end

    def display_name
      @user['display_name']
    end

    def email
      @user['email']
    end

    def language
      @user['language']
    end

    def preferred_language
      @user['preferred_language']
    end

    def preferred_language?
      preferred_language.present?
    end

    private

    def permissions_for(context)
      return @permissions unless context

      @permission_map.fetch(context) do
        @permission_map[context] = Restify.new(@user['permissions_url'])
          .get(context:).value!
      end
    end
  end

  class Anonymous < Base
    def id
      'anonymous'
    end

    def anonymous?
      true
    end

    def logged_in?
      false
    end
    alias authenticated? logged_in?

    def preferences
      @preferences ||= Restify::Promise.fulfilled({})
    end

    def interrupts
      []
    end

    # @deprecated
    def interrupt_session?
      false
    end
  end

  class Authenticated < Base
    def anonymous?
      false
    end

    def logged_in?
      true
    end
    alias authenticated? logged_in?

    def preferences
      @preferences ||= @session['user'].rel(:preferences).get.then {|preferences| preferences['properties'] }
    end
  end
end

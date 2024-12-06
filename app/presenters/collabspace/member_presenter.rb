# frozen_string_literal: true

module Collabspace
  class MemberPresenter
    extend Forwardable

    def_delegators :user, :id, :name, :email
    attr_accessor :user, :membership

    def initialize(user:, membership:)
      @user = user
      @membership = membership
    end

    def status
      @membership['status']
    end

    def pending?
      status == 'pending'
    end

    def regular?
      status == 'regular'
    end

    def admin?
      status == 'admin'
    end

    def mentor?
      status == 'mentor'
    end

    def privileged?
      admin? || mentor?
    end

    def display
      return name if regular?

      "#{name} (#{status.capitalize})"
    end
  end
end

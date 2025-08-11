# frozen_string_literal: true

module Admin
  module Ajax
    class UsersController < Abstract::AjaxController
      respond_to :json

      before_action :ensure_logged_in
      require_permission 'account.user.find'

      def index
        users = account_api.rel(:users).get({
          query: params[:q],
        }).value!

        render json: users.map {|u| {id: u['id'], text: "#{u['name']} (#{u['email']})"} }
      end
    end
  end
end

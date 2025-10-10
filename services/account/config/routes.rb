# frozen_string_literal: true

Xikolo::Account::Application.routes.draw do
  mount AccountService::Engine => '/'
end

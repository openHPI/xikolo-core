# frozen_string_literal: true

# Be sure to restart your server when you modify this file.

Xikolo::Web::Application.config.session_store :cookie_store, key: '_openhpi_session', secure: Rails.env.production?

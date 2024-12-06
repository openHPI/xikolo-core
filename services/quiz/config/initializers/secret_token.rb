# frozen_string_literal: true

# Be sure to restart your server when you modify this file.

# Your secret key for verifying the integrity of signed cookies.
# If you change this key, all old signed cookies will become invalid!

# Make sure the secret is at least 30 characters and all random,
# no regular words or you'll be exposed to dictionary attacks.
# You can use `rake secret` to generate a secure secret key.

# Make sure your secret_key_base is kept private
# if you're sharing your code publicly.

# Although this is not needed for an api-only application, rails4
# requires secret_key_base or secret_toke to be defined, otherwise an
# error is raised.
# Using secret_token for rails3 compatibility. Change to secret_key_base
# to avoid deprecation warning.
# Can be safely removed in a rails3 api-only application.
Xikolo::QuizService::Application.config.secret_key_base = 'ef1d7a107aa22998533f0492958382c0c69344c6fc58f6213d40cbe40c81d1e2c07306490c0be729ccf181106d5b24ed4073d68bc43803f339759f3467c1f9f2'

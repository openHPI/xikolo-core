# frozen_string_literal: true

require_relative '../acfs_auth_middleware'

module Xikolo::Quiz
  # Service definition needs to subclass `Acfs::Service`.
  # This allows you to use the Acfs Service DSL to describe
  # your service e.g. used middlewares.
  #
  class Client < Acfs::Service
    # First define an identity for your service.
    # This names will be used to lookup service settings
    # like service base URI.
    #
    identity :quiz

    # Define used middleware e.g. for JSON decoding.
    use Acfs::Middleware::JsonDecoder
    use Acfs::Middleware::JsonEncoder
    use AcfsAuthMiddleware

    class SystemInfo < Acfs::Resource
      service Xikolo::Quiz::Client, path: 'system_info'

      attribute :running, :boolean
      attribute :build_time, :string
      attribute :build_number, :integer
      attribute :version, :string
      attribute :hostname, :string
    end

    # Require defined resources here
    require 'xikolo/quiz/quiz'

    require 'xikolo/quiz/question'
    require 'xikolo/quiz/multiple_answer_question'
    require 'xikolo/quiz/multiple_choice_question'
    require 'xikolo/quiz/free_text_question'
    require 'xikolo/quiz/essay_question'

    require 'xikolo/quiz/answer'
    require 'xikolo/quiz/text_answer'
    require 'xikolo/quiz/free_text_answer'
  end
end

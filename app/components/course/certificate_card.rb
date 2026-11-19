# frozen_string_literal: true

module Course
  # A certificate the learner can achieve in a course, with its requirement,
  # issue date and download.
  class CertificateCard < ApplicationComponent
    # @param title [String]
    # @param description [String]
    # @param requirement [String]
    # @param issued_on [String] issue date or a placeholder text
    # @param achieved [Boolean]
    # @param download_path [String, nil] the download is disabled without a path
    def initialize(title:, description:, requirement:, issued_on:, achieved: false, download_path: nil)
      @title = title
      @description = description
      @requirement = requirement
      @issued_on = issued_on
      @achieved = achieved
      @download_path = download_path
    end

    private

    def achieved?
      @achieved
    end

    def badge_classes
      if achieved?
        'x-badge x-badge-success'
      else
        'x-badge x-badge-outline border-base-300 bg-base-100'
      end
    end

    def badge_icon
      achieved? ? 'check' : 'lock'
    end

    def badge_text
      achieved? ? t('course.certificate_card.achieved') : t('course.certificate_card.pending')
    end
  end
end

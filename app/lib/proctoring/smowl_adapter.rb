# frozen_string_literal: true

require 'base64'

module Proctoring
  class SmowlAdapter
    # @param course [Course::Course]
    def initialize(course)
      @course = course
    end

    # Read the proctoring results for a quiz from a stored vendor data hash
    #
    # @return [Proctoring::Result]
    def results_from_data(vendor_data)
      if vendor_data['proctoring_smowl_v2']
        Proctoring::Result.new vendor_data['proctoring_smowl_v2'], thresholds: thresholds_v2
      elsif vendor_data['proctoring_smowl']
        Proctoring::Result.new vendor_data['proctoring_smowl'], thresholds: thresholds_v1
      else
        Proctoring::Result.new({}, thresholds: thresholds_v1)
      end
    end

    # @deprecated Should be replaced by locally accumulating cached submission
    # data, see `results_from_data` above.
    # @param user [Xikolo::Common::Auth::CurrentUser::Authenticated]
    # @return [Boolean]
    def passed?(_user)
      # Temporary: Since we cannot load data anymore, we need to assume
      # proctoring has not been passed.
      false
    end

    private

    SMOWL_FEATURES_V1 = %w[
      nobody wronguser morepeople covered
      wrongimage discarted cheat othertab black
    ].freeze
    private_constant :SMOWL_FEATURES_V1

    # The 'suspicious' feature is explicitly excluded as this was an
    # experimental feature for some SMOWL customers but is not
    # considered anymore on SMOWL side.
    SMOWL_FEATURES_V2 = %w[
      nobodyinthepicture wronguser severalpeople webcamcovered
      invalidconditions webcamdiscarted notallowedelement nocam
      otherappblockingthecam notsupportedbrowser othertab emptyimage
    ].freeze
    private_constant :SMOWL_FEATURES_V2

    def thresholds_v1
      SMOWL_FEATURES_V1.index_with {|key| Proctoring.smowl_option(key) }
    end

    def thresholds_v2
      SMOWL_FEATURES_V2.index_with {|key| Proctoring.smowl_option(key) }
    end
  end
end

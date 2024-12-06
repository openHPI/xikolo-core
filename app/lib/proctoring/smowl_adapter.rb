# frozen_string_literal: true

require 'base64'

module Proctoring
  class SmowlAdapter
    # @param course [Course::Course]
    def initialize(course)
      @course = course
    end

    # Determine the user's status with the provider.
    #
    # NOTE: This method does *not* raise exceptions on SMOWL failures. Instead,
    # this state is encapsulated in the returned object. See
    # +Proctoring::Registration_status#available?+.
    #
    # @param user_id [String]
    # @return [Proctoring::RegistrationStatus]
    def registration_status(user_id)
      @registration_status ||= begin
        response = request('ConfirmRegistration',
          entity: Proctoring.entity, idUser: user_id(user_id))

        status = {
          0 => :complete,
          -1 => :pending,
          -2 => :required,
          -3 => :required,
        }.fetch(response.data&.dig('ack'))

        RegistrationStatus.new(status)
      rescue Proctoring::ServiceError
        RegistrationStatus.new(nil)
      end
    end

    # Determine the URL where the given user can register with the vendor.
    #
    # @param user_id [String]
    # @param redirect_to [String]
    # @return [String]
    def registration_url(user_id, redirect_to:)
      Addressable::Template.new(endpoint('register')).expand(
        query: {
          entity_Name: entity,
          swlLicenseKey: license_key,
          user_idUser: user_id(user_id),
          lang: I18n.locale,
          Course_link: redirect_to,
        }
      ).to_s
    end

    # Fetch the user image to be printed on the certificate.
    #
    # @param user_id [String]
    # @return [String, nil] A byte stream of the image
    def fetch_image(user_id)
      return unless registration_status(user_id).complete?

      authenticated_request(
        'Getimage_jpg_Registration',
        idUser: user_id(user_id)
      ).data
        .fetch('image')
        .then { Base64.decode64 _1 }
    end

    # The URL for an embeddable iframe that allows *previewing* the proctoring
    def cam_preview_url
      Addressable::Template.new(endpoint('camera_check')).expand(
        entity_Name: entity,
        lang: I18n.locale
      ).to_s
    end

    # The URL for an embeddable iframe that starts the actual proctoring
    #
    # @param submission [Restify::Resource]
    # @param redirect_to [String]
    def cam_url(submission, redirect_to:)
      Addressable::Template.new(endpoint('proctoring')).expand(
        query: {
          entity_Name: entity,
          swlLicenseKey: license_key,
          modality_ModalityName: 'quiz',
          course_CourseName: quiz_id(submission),
          course_Container: @course.course_code,
          user_idUser: user_id(submission['user_id']),
          lang: I18n.locale,
          type: 0,
          Course_link: redirect_to,
        }
      ).to_s
    end

    # Fetch the proctoring results for the given quiz submission
    # Although the *idActivity* is already user-specific as we incorporate
    # the quiz submission, SMOWL requires the *idUser* to be set.
    #
    # @param submission [Restify::Resource]
    # @return [Hash{String => Integer}] A map of features and
    #   corresponding occurrences
    def submission_results(submission)
      params = {
        modality: 'quiz',
        idActivity: quiz_id(submission),
        idUser: user_id(submission['user_id']),
      }

      # Check whether the proctoring results are ready on the SMOWL side. This
      # is required (and recommended by SMOWL) as the response format in case
      # of not ready results deviates from the typical '*Response' key
      # convention, which is expected by the client for accessing data.
      unless authenticated_request('Results_Ready_Activity', params).acknowledged?
        return {}
      end

      authenticated_request('Get_Results_Array', params).data
        .fetch('results').compact.transform_keys(&:downcase)
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

    # @deprecated Should be replaced by locally accumulating cached submission data.
    # @param user [Xikolo::Common::Auth::CurrentUser::Authenticated]
    # @return [Boolean]
    def passed?(user)
      authenticated_request(
        'Passed_Fail_Course',
        idUser: user_id(user.id),
        idCourse: @course.course_code,
        # Use the absolute number of images, not a percentage.
        alarm_type: 1,
        a1_Nobody: option('nobodyinthepicture'),
        a2_IncorrectUser: option('wronguser'),
        a3_MorePeople: option('severalpeople'),
        a4_Covered: option('webcamcovered'),
        # NOTE: Do not fix the "Imag" typo. It's that way on the SMOWL side.
        a5_ImagNotValid: option('invalidconditions'),
        # NOTE: Do not fix the "Discarted" typo. It's that way on the SMOWL side.
        a6_Discarted: option('webcamdiscarted'),
        a7_NotAllowedElements: option('notallowedelement'),
        a8_Tab: option('othertab'),
        a9_ConfigProblem: option('emptyimage'),
        a10_NotSupportedBrowser: option('notsupportedbrowser'),
        a11_Nocam: option('nocam'),
        a12_Otherapp: option('otherapp'),
        a14_CorrectImages: option('correctimages')
      ).acknowledged?
    rescue Restify::ResponseError
      # Swallow errors, e.g. for unauthorized requests and handle such cases
      # as "not passed". This covers even more failures than the regular error
      # handling in the #request method.
      false
    end

    def exclude_from_proctoring!(submission)
      authenticated_request('Disable_Submission', {
        modality: 'quiz',
        idActivity: quiz_id(submission),
      })
    end

    private

    def user_id(id)
      Digest::SHA256.hexdigest id
    end

    # SMOWL only supports quizzes, not submissions.
    # To be able to differentiate between various attempts for a quiz, we construct
    # an ID for this quiz submission consisting of the quiz ID and the submission ID.
    def quiz_id(submission)
      "#{UUID4(submission['quiz_id']).to_s(format: :base62)}_#{UUID4(submission['id']).to_s(format: :base62)}"
    end

    def authenticated_request(function, params)
      request(function, {
        entity:,
        password:,
      }.merge(params))
    end

    def request(function, params)
      client.request(function, params)
    rescue ::Smowl::ServiceError
      raise Proctoring::ServiceError
    end

    # @return [Smowl::Client]
    def client
      @client ||= ::Smowl::Client.new endpoint('api_base')
    end

    def endpoint(key)
      Xikolo.config.proctoring_smowl_endpoints[key]
    end

    def option(key)
      Xikolo.config.proctoring_smowl_options[key]
    end

    def entity
      Rails.application.secrets.smowl_entity
    end

    def license_key
      Rails.application.secrets.smowl_license_key
    end

    def password
      Rails.application.secrets.smowl_password
    end

    SMOWL_FEATURES_V1 = %w[
      nobody wronguser morepeople covered
      wrongimage discarted cheat othertab black
    ].freeze

    # The 'suspicious' feature is explicitly excluded as this was an
    # experimental feature for some SMOWL customers but is not
    # considered anymore on SMOWL side.
    SMOWL_FEATURES_V2 = %w[
      nobodyinthepicture wronguser severalpeople webcamcovered
      invalidconditions webcamdiscarted notallowedelement nocam
      otherappblockingthecam notsupportedbrowser othertab emptyimage
    ].freeze

    def thresholds_v1
      SMOWL_FEATURES_V1.index_with do |key|
        option(key)
      end
    end

    def thresholds_v2
      SMOWL_FEATURES_V2.index_with do |key|
        option(key)
      end
    end
  end
end

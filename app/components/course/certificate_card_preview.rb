# frozen_string_literal: true

module Course
  class CertificateCardPreview < ViewComponent::Preview
    COP = 'Confirmation of Participation'
    COP_REQUIREMENT = 'Complete at least 50% of the learning units.'
    ROA = 'Certificate'
    ROA_REQUIREMENT = 'Achieve 50% of the overall score in graded assignments.'

    # @!group Certificate card

    # @label In progress (records not released)
    def in_progress
      render ::Course::CertificateCard.new(
        title: ROA,
        description: 'You did not score enough points in graded exams, yet.',
        requirement: ROA_REQUIREMENT,
        issued_on: 'Not available yet'
      )
    end

    # @label Achieved (records not released)
    def achieved_not_released
      render ::Course::CertificateCard.new(
        title: COP,
        description: 'Congratulations on achieving a confirmation for this course! Once the confirmation is ' \
                     'released by the teaching team, you can download it here.',
        requirement: COP_REQUIREMENT,
        issued_on: 'Not available yet',
        achieved: true
      )
    end

    # @label Achieved, not downloaded yet
    def achieved_not_issued
      render ::Course::CertificateCard.new(
        title: ROA,
        description: 'Congratulations! You achieved a certificate for this course by scoring high enough in ' \
                     'the graded assignments.',
        requirement: ROA_REQUIREMENT,
        issued_on: 'Not downloaded yet',
        achieved: true,
        download_path: '#'
      )
    end

    # @label Achieved and downloaded
    def achieved_issued
      render ::Course::CertificateCard.new(
        title: COP,
        description: 'Congratulations! You achieved a confirmation for this course.',
        requirement: COP_REQUIREMENT,
        issued_on: '10/29/2026',
        achieved: true,
        download_path: '#'
      )
    end

    # @label Achieved via the certificate
    def achieved_via_certificate
      render ::Course::CertificateCard.new(
        title: COP,
        description: 'Congratulations! You have achieved the Confirmation of Participation in this course by ' \
                     'obtaining the Certificate of Achievement.',
        requirement: COP_REQUIREMENT,
        issued_on: 'Not downloaded yet',
        achieved: true,
        download_path: '#'
      )
    end

    # @label Not achieved, course ended
    def no_longer_achievable
      render ::Course::CertificateCard.new(
        title: ROA,
        description: 'This course has ended. Certificates were only available during the active course period.',
        requirement: ROA_REQUIREMENT,
        issued_on: '—'
      )
    end
    # @!endgroup
  end
end

# frozen_string_literal: true

module Course
  class SocialSharingPreview < ViewComponent::Preview
    def for_certificates
      render ::Course::SocialSharing.new(context: :certificate, services: %w[facebook mail linkedin_add],
        options: {site: 'Xikolo',
          title: 'Cloud und Virtualisierung',
          certificate_url: '/verify/2wer-234',
          course_url: 'courses/cloud2013',
          issued_year: 2025,
          issued_month: 2})
    end
  end
end

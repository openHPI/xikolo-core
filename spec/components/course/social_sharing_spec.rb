# frozen_string_literal: true

require 'spec_helper'

describe Course::SocialSharing, type: :component do
  subject(:component) do
    described_class.new(
      context: context,
      services: services,
      options: options
    )
  end

  let(:context) { nil }
  let(:services) { %w[linkedin_add mail facebook] }
  let(:options) { nil }

  it 'raises an error if no context is given' do
    expect { render_inline(component) }.to raise_error(RuntimeError, /unknown sharing context/)
  end

  context 'with certificates context' do
    let(:context) { :certificate }
    let(:options) do
      {
        site: 'Xikolo',
        title: 'Cloud und Virtualisierung',
        certificate_url: '/verify/2wer-234',
        course_url: 'courses/cloud2013',
        issued_year: 2025,
        issued_month: 2,
      }
    end

    let(:linkedin_params) do
      {
        certId: options[:site],
        certUrl: options[:certificate_url],
        issueYear: options[:issued_year],
        issueMonth: options[:issued_month],
        name: options[:title],
        organizationId: Xikolo.config.linkedin_organization_id,
      }.compact.to_query
    end

    let(:mail_subject) { ERB::Util.url_encode(I18n.t(:'social_sharing.mail.share_certificate.subject', site: options[:site])) }
    let(:body) do
      ERB::Util.url_encode(I18n.t(:'social_sharing.mail.share_certificate.body',
        site: options[:site],
        title: options[:title],
        certificate_url: options[:certificate_url],
        course_url: options[:course_url]))
    end

    it 'renders a mail link with correct href' do
      render_inline(component)

      expect(page).to have_link('Mail', href: "mailto:?subject=#{mail_subject}&body=#{body}")
    end

    it 'renders a LinkedIn "Add to profile" link' do
      render_inline(component)

      expect(page).to have_link('Add to profile', href: "https://www.linkedin.com/profile/add?startTask=CERTIFICATION_NAME&#{linkedin_params}")
    end

    it 'renders a Facebook share link' do
      render_inline(component)

      expect(page).to have_link('Share', href: "https://www.facebook.com/sharer/sharer.php?u=#{options[:certificate_url]}")
    end
  end
end

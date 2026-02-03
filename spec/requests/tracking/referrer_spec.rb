# frozen_string_literal: true

require 'spec_helper'

describe 'Tracking: Referrers', type: :request do
  subject(:homepage) { get '/', params:, headers: }

  before do
    Stub.request(:news, :get, '/current_alerts')
      .with(query: hash_including({}))
      .to_return Stub.json([])
    Stub.request(:news, :get, '/news')
      .with(query: hash_including({}))
      .to_return Stub.json([])
  end

  let(:params) { {} }
  let(:headers) { {} }

  context 'without special parameters' do
    it 'does not track a referrer' do
      expect(Msgr).not_to receive(:publish).with(anything, to: 'xikolo.web.referrer')
      homepage
    end
  end

  context 'with an invalid HTTP Referer (sic!) header' do
    let(:headers) { super().merge('Referer' => 'http/foobaz') }

    it 'does not track a referrer' do
      expect(Msgr).not_to receive(:publish).with(anything, to: 'xikolo.web.referrer')
      homepage
    end
  end

  context 'with the Referer (sic!) header containing a valid internal HTTP URL' do
    let(:headers) { super().merge('Referer' => 'http://xikolo.de/pages/about') } # Note the platform domain

    it 'does not track a referrer' do
      expect(Msgr).not_to receive(:publish).with(anything, to: 'xikolo.web.referrer')
      homepage
    end
  end

  context 'with the Referer (sic!) header containing a valid internal HTTPS URL' do
    let(:headers) { super().merge('Referer' => 'https://xikolo.de/courses/learn-coding') } # Note the platform domain

    it 'does not track a referrer' do
      expect(Msgr).not_to receive(:publish).with(anything, to: 'xikolo.web.referrer')
      homepage
    end
  end

  context 'with the Referer (sic!) header containing a valid external URL' do
    let(:headers) { super().merge('Referer' => 'http://www.google.de/search?q=foobar') }

    it 'tracks the referrer (without protocol)' do
      expect(Msgr).to receive(:publish).with(
        hash_including(
          'created_at',
          'referrer' => 'www.google.de/search?q=foobar',
          'referrer_page' => 'http://www.example.com/' # Rails' default host when testing
        ),
        to: 'xikolo.web.referrer'
      )
      homepage
    end

    context 'with logo param' do
      let(:params) { super().merge(logo: true) }

      # We add this parameter to notification emails so that we can track
      # when these emails are opened. Since these are no real clicks, we
      # don't want to track the referrer, though.
      it 'does not track a referrer' do
        expect(Msgr).not_to receive(:publish).with(anything, to: 'xikolo.web.referrer')
        homepage
      end
    end

    context 'with additional tracking parameters' do
      let(:params) do
        super().merge(
          url: 'http://www.google.de', # This maps to tracking_external_link
          tracking_campaign: '5th_birthday',
          tracking_id: 'abc123',
          tracking_course_id: 'cloud2014',
          tracking_type: 'news'
        )
      end

      it 'tracks the referrer, including the additional parameters' do
        expect(Msgr).to receive(:publish).with(
          hash_including(
            'created_at', 'referrer', 'referrer_page',
            'tracking_external_link' => 'http://www.google.de',
            'tracking_campaign' => '5th_birthday',
            'tracking_id' => 'abc123',
            'tracking_course_id' => 'cloud2014',
            'tracking_type' => 'news'
          ),
          to: 'xikolo.web.referrer'
        )
        homepage
      end

      describe '[tracking_user]' do
        context 'not given' do
          let(:params) { super().except(:tracking_user) }

          context 'for anonymous user' do
            it 'does not track any user ID' do
              expect(Msgr).to receive(:publish).with(
                hash_excluding('user_id'),
                to: 'xikolo.web.referrer'
              )
              homepage
            end
          end

          context 'for logged-in user' do
            let!(:user) { stub_user_request }
            let(:headers) { super().merge('Authorization' => "Xikolo-Session session_id=#{stub_session_id}") }

            it 'tracks the ID of the current user' do
              expect(Msgr).to receive(:publish).with(
                hash_including('user_id' => user[:id]),
                to: 'xikolo.web.referrer'
              )
              homepage
            end
          end
        end

        context 'given' do
          let(:params) { super().merge(tracking_user: user_id_param) }

          context 'for anonymous user' do
            context 'with a valid UUID' do
              let(:user_id_param) { SecureRandom.uuid }

              it 'uses the parameter as user ID' do
                expect(Msgr).to receive(:publish).with(
                  hash_including('user_id' => user_id_param),
                  to: 'xikolo.web.referrer'
                )
                homepage
              end
            end

            context 'with an invalid UUID' do
              let(:user_id_param) { 'i-am-a-real-uuid-trust-me-001' }

              it 'does not track any user ID' do
                expect(Msgr).to receive(:publish).with(
                  hash_excluding('user_id'),
                  to: 'xikolo.web.referrer'
                )
                homepage
              end
            end
          end

          context 'for logged-in user' do
            let!(:user) { stub_user_request }
            let(:headers) { super().merge('Authorization' => "Xikolo-Session session_id=#{stub_session_id}") }

            context 'with a valid UUID' do
              let(:user_id_param) { SecureRandom.uuid }

              it 'tracks the ID of the current user (ignoring the parameter)' do
                expect(Msgr).to receive(:publish).with(
                  hash_including('user_id' => user[:id]),
                  to: 'xikolo.web.referrer'
                )
                homepage
              end
            end
          end
        end
      end
    end
  end

  describe 'on a course page' do
    subject(:course_page) do
      get "/courses/#{course['course_code']}",
        params:, headers:
    end

    let(:course) { build(:'course:course') }

    # Authenticate user
    let(:headers) do
      super().merge(
        'Authorization' => "Xikolo-Session session_id=#{stub_session_id}",
        'Referer' => 'http://www.google.de/search?q=foobar'
      )
    end
    let!(:user) { stub_user_request permissions: ['course.content.access'] }

    # Stub service resources for course
    before do
      Stub.request(:course, :get, "/courses/#{course['course_code']}")
        .to_return Stub.json(course)
      Stub.request(:course, :get, '/enrollments',
        query: {course_id: course['id'], user_id: user[:id]})
        .to_return Stub.json([])
      Stub.request(
        :course, :get, '/next_dates',
        query: hash_including({})
      ).to_return Stub.json([])
    end

    it 'tracks the referrer and includes the course ID' do
      expect(Msgr).to receive(:publish).with(
        hash_including(
          'referrer' => 'www.google.de/search?q=foobar',
          'course_id' => course['id']
        ),
        to: 'xikolo.web.referrer'
      )
      course_page
    end
  end
end

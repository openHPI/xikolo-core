# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Course: BadgeClass', type: :request do
  let(:badge_class_response) { get "/courses/#{course.id}/openbadges/v2/class.json"; response }

  let(:course) { create(:course, course_params) }
  let(:course_params) { {course_code: 'my-course', title: 'The Course', records_released: true, end_date: nil} }
  let(:response_body) { JSON.parse(badge_class_response.body) }
  let(:badge_template_params) { {course:, name: 'The Open Badge', description: 'Description of the Open Badge'} }

  before do
    create(
      :open_badge_template,
      badge_template_params
    )
  end

  context 'when open_badges option enabled in config' do
    before do
      xi_config <<~YML
        open_badges:
          enabled: true
      YML
    end

    it 'returns correct HTTP status' do
      expect(badge_class_response).to have_http_status :ok
    end

    it 'returns valid json' do
      expect(badge_class_response.header['Content-Type']).to eq('application/json; charset=utf-8')
      expect { response_body }.not_to raise_error
    end

    it 'returns valid badge class structure' do
      expect(response_body.values).to all(be_an_instance_of(String))
    end

    it 'returns valid badge class attributes' do
      expect(response_body['@context']).to eq('https://w3id.org/openbadges/v2')
      expect(response_body['type']).to eq('BadgeClass')
      expect(response_body['id']).to eq('http://www.example.com/courses/my-course/openbadges/v2/class.json')
      expect(response_body['name']).to eq('The Open Badge')
      expect(response_body['description']).to eq('Description of the Open Badge')
      expect(response_body['image']).to match(%r{https://s3.xikolo.de/xikolo-certificate/openbadge_templates/\w+.png})
      expect(response_body['criteria']).to eq('http://www.example.com/courses/my-course')
      expect(response_body['issuer']).to eq('http://www.example.com/openbadges/v2/issuer.json')
    end

    context 'for Open Badges V1' do
      let(:badge_class_response) { get "/courses/#{course.id}/badge.json"; response }

      it 'returns valid badge class attributes' do
        expect(response_body['@context']).to eq('https://w3id.org/openbadges/v1')
        expect(response_body['type']).to eq('BadgeClass')
        expect(response_body['id']).to eq('http://www.example.com/courses/my-course/badge.json')
        expect(response_body['name']).to eq('The Open Badge')
        expect(response_body['description']).to eq('Description of the Open Badge')
        expect(response_body['image']).to match(%r{https://s3.xikolo.de/xikolo-certificate/openbadge_templates/\w+.png})
        expect(response_body['criteria']).to eq('http://www.example.com/courses/my-course')
        expect(response_body['issuer']).to eq('http://www.example.com/openbadges/issuer.json')
      end
    end

    context 'without explicit name and description' do
      let(:badge_template_params) { super().merge name: nil, description: nil }

      it 'creates badge name and description from the fallback locales' do
        expect(response_body['name']).to eq('Successfully completed: The Course')
        expect(response_body['description']).to eq('This badge verifies that the candidate completed the openHPI course "The Course" and passed the necessary exercises and exams to earn a course certificate.')
      end

      context 'when course language is not an available locale' do
        let(:course_params) { super().merge lang: 'ar' }

        it 'falls back to the default locale' do
          expect(response_body['name']).to eq('Successfully completed: The Course')
          expect(response_body['description']).to eq('This badge verifies that the candidate completed the openHPI course "The Course" and passed the necessary exercises and exams to earn a course certificate.')
        end
      end

      context 'with course end date' do
        let(:end_date) { Time.zone.today - 1.week }
        let(:course_params) { super().merge end_date: }

        it 'creates the badge name from the locales' do
          expect(response_body['name']).to eq("Successfully completed in #{end_date.year}: The Course")
        end

        context 'when course language is not an available locale' do
          let(:course_params) { super().merge(lang: 'ar') }

          it 'creates the badge name from the locales' do
            expect(response_body['name']).to eq("Successfully completed in #{end_date.year}: The Course")
          end
        end
      end
    end
  end

  context 'when open_badges option disabled in config' do
    before do
      xi_config <<~YML
        open_badges:
          enabled: false
      YML
    end

    it 'returns not_found HTTP status' do
      expect(badge_class_response).to have_http_status :not_found
    end
  end
end

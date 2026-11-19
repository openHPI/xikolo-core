# frozen_string_literal: true

require 'uri'
require 'spec_helper'

describe Cmi5ItemPresenter, type: :presenter do
  let(:cmi5_item) { create(:cmi5_item) }
  let(:course) { create(:'course_service/course') }
  let(:user) { create(:'account_service/user') }
  let(:enrollment) { create(:'course_service/enrollment', course:, user_id: user.id) }

  let(:item_params) do
    {
      content_id: cmi5_item.id,
      content_type: 'cmi5',
    }
  end
  let(:item) { build(:'course:item', **item_params) }
  let(:presenter) { described_class.new(item:, course:, user:) }

  describe '#launch_url' do
    let(:launch_url) { presenter.launch_url }

    before { enrollment }

    it 'includes all required CMI-5 parameters' do
      required_params = %w[activityId registration endpoint fetch actor]
      required_params.each do |param|
        expect(launch_url).to include("#{param}=")
      end
    end

    it 'includes the package blob id in the content path' do
      expect(launch_url).to include("/content/#{cmi5_item.package.blob_id}/index_lms.html")
    end

    context 'activityId validation' do
      let(:activity_id) do
        uri = URI.parse(launch_url)
        params = URI.decode_www_form(uri.query)
        params_hash = params.to_h
        params_hash['activityId']
      end

      it 'generates an absolute IRI' do
        expect(URI.parse(activity_id)).to be_absolute
      end

      it 'includes the cmi5 item ID' do
        expect(activity_id).to include(cmi5_item.id)
      end

      context 'when called multiple times' do
        it 'returns the same activity ID' do
          first_call = extract_activity_id(presenter.launch_url)
          second_call = extract_activity_id(presenter.launch_url)
          expect(first_call).to eq(second_call)
        end
      end

      context 'with different cmi5 items' do
        let(:another_cmi5_item) { create(:cmi5_item) }
        let(:another_presenter) do
          another_item = build(:'course:item', **item_params, content_id: another_cmi5_item.id)
          described_class.new(
            item: another_item,
            course:,
            user:
          )
        end

        it 'generates different activity IDs for different cmi5 items' do
          first_activity_id = extract_activity_id(presenter.launch_url)
          second_activity_id = extract_activity_id(another_presenter.launch_url)
          expect(first_activity_id).not_to eq(second_activity_id)
        end
      end

      context 'with different users' do
        let(:another_user) { create(:'account_service/user') }
        let(:another_enrollment) { create(:'course_service/enrollment', course:, user_id: another_user.id) }
        let(:another_presenter) do
          described_class.new(item:, course:, user: another_user)
        end

        before { another_enrollment }

        it 'uses the same activity ID for the same AU' do
          first_activity_id = extract_activity_id(presenter.launch_url)
          second_activity_id = extract_activity_id(another_presenter.launch_url)
          expect(first_activity_id).to eq(second_activity_id)
        end
      end
    end

    context 'actor validation' do
      it 'uses an absolute account home page' do
        actor = extract_launch_parameter(launch_url, 'actor').then { JSON.parse(it) }

        expect(URI.parse(actor.dig('account', 'homePage'))).to be_absolute
      end
    end

    context 'registration validation' do
      let(:registration) do
        uri = URI.parse(launch_url)
        params = URI.decode_www_form(uri.query)
        params_hash = params.to_h
        params_hash['registration']
      end

      context 'when user is enrolled' do
        let(:enrolled_user) { create(:'account_service/user') }
        let(:user) { enrolled_user }

        let(:registration) do
          uri = URI.parse(launch_url)
          params = URI.decode_www_form(uri.query)
          params_hash = params.to_h
          params_hash['registration']
        end

        it 'uses the enrollment ID for registration' do
          expect(registration).to eq(enrollment.id)
        end
      end

      context 'when user is not actively enrolled' do
        let(:enrollment) { nil }

        it 'does not generate a launch URL' do
          expect { launch_url }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end
    end
  end

  def extract_activity_id(launch_url)
    extract_launch_parameter(launch_url, 'activityId')
  end

  def extract_launch_parameter(launch_url, name)
    uri = URI.parse(launch_url)
    params = URI.decode_www_form(uri.query)
    params.to_h[name]
  end
end

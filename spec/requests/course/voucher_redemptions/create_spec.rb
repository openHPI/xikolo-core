# frozen_string_literal: true

require 'spec_helper'

describe 'Voucher Redemptions: Create', type: :request do
  subject(:redeem_voucher) do
    post "/courses/#{course.course_code}/book/#{product_type}", headers:, params:
  end

  before do
    xi_config <<~YML
      voucher:
        enabled: true
    YML

    role = create(:'account_service/role', permissions:)
    create(:'account_service/grant', principal: user, role:, context: course_context)
    user.features.create(name: 'course_reactivation', value: 'true', context: AccountService::Context.root)
    set_session(id: session.id)
  end

  let(:params) { {voucher_redemption: {code: voucher.id}} }
  let(:headers) { {'Authorization' => "Xikolo-Session session_id=#{session.id}"} }
  let(:request_context_id) { course.context_id }
  let(:course_context) { create(:'account_service/context') }
  let(:session) { create(:'account_service/session', user:) }
  let(:user) { create(:'account_service/user') }
  let(:user_id) { user.id }
  let(:permissions) { %w[course.content.access] }
  let(:page) { Capybara.string(response.body) }

  context 'with an unknown product type' do
    let(:product_type) { 'unknown' }
    let(:course) { create(:course, :active, context_id: course_context.id) }
    # Use :reactivation because it is the only remaining product type trait after proctoring removal.
    let(:voucher) { create(:voucher, :reactivation) }

    it 'responds with 404 Not Found' do
      expect { redeem_voucher }.to raise_error Status::NotFound
    end
  end

  describe 'reactivation' do
    let(:product_type) { 'course_reactivation' }
    let(:course) { create(:course, :archived, :offers_reactivation, context_id: course_context.id) }
    let(:voucher) { create(:voucher, :reactivation) }

    let!(:claim_stub) do
      Stub.request(:course, :post, '/enrollment/1/reactivations')
        .to_return do
          # HACK: The code relies on the reactivated enrollment,
          # so let's simulate that here.
          create(:enrollment, :reactivated, course:, user_id:)

          Stub.response(status: 201)
        end
    end

    before do
      Stub.request(:course, :post, '/enrollments')
        .with(body: hash_including(
          course_id: course.id,
          user_id:
        ))
        .to_return Stub.json({reactivations_url: '/course_service/enrollment/1/reactivations'})
    end

    it 'redeems the voucher' do
      redeem_voucher

      voucher.reload
      expect(voucher.claimant_id).to eq user_id
      expect(voucher.course_id).to eq course.id
      expect(claim_stub).to have_been_requested
    end

    it 'redirects to the course page' do
      redeem_voucher

      expect(response).to redirect_to course_path(course.course_code)
    end

    context 'with voucher redemption error' do
      let(:voucher) do
        create(:voucher, :reactivation, claimant_id: generate(:user_id))
      end

      it 're-renders the form with an error' do
        redeem_voucher

        expect(response).to render_template(:new)
        expect(page).to have_content 'Reactivate this course'
        expect(page).to have_css "input[value='#{voucher.id}']"
        expect(page).to have_button 'Redeem'
        expect(flash[:error].first).to eq 'The voucher code you have supplied is not valid for your user account.'
      end
    end
  end
end

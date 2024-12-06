# frozen_string_literal: true

require 'spec_helper'

describe Voucher::Claim, type: :operation do
  subject(:claim_voucher) { described_class.call(voucher_code, product_type, course, current_user, **opts) }

  let(:voucher_code) { voucher.id }
  let(:voucher) { create(:voucher, :reactivation) }
  let(:product_type) { Voucher::ProductTypes.resolve 'course_reactivation' }
  let(:course) { create(:course, :archived, :offers_reactivation) }
  let(:user_id) { generate(:user_id) }
  let(:current_user) do
    Xikolo::Common::Auth::CurrentUser.from_session(
      'user_id' => user_id,
      'features' => {'course_reactivation' => true},
      'user' => {'anonymous' => false},
      'masqueraded' => false
    )
  end
  let(:opts) do
    {
      claimant_ip: '216.3.128.12', # USA IP address
    }
  end

  before do
    # This spec tests voucher redemption based on course reactivation.
    # As the overall process and product type interfaces are the same,
    # proctoring is not considered here. See `ProductTypes::PRODUCT#claim!`
    # `ProductTypes::PRODUCT#enabled_in?`, and `ProductTypes::PRODUCT#valid?`
    # for product-specific errors.
    xi_config <<~YML
      course_reactivation:
        period: 8
        store_url:
          en: https://www.shop.com
          fr: https://www.shop.fr
      voucher:
        enabled: true
    YML

    Stub.service(:course, enrollments_url: '/enrollments{?course_id,user_id}')

    Stub.request(
      :course, :post, '/enrollments',
      body: {course_id: course.id, user_id: current_user.id}
    ).to_return Stub.json({reactivations_url: '/enrollment/0/reactivations'})
    Stub.request(
      :course, :post, '/enrollment/0/reactivations',
      body: hash_including(:submission_date)
    ).to_return do
      # HACK: The code relies on the reactivated enrollment,
      # so let's simulate that here.
      create(:enrollment, :reactivated, course:, user_id: current_user.id)

      Stub.response(status: 201)
    end
  end

  describe '(early failures)' do
    context 'as anonymous user' do
      let(:current_user) do
        Xikolo::Common::Auth::CurrentUser.from_session(
          'user_id' => 'anonymous',
          'features' => {'course_reactivation' => true},
          'user' => {'anonymous' => true},
          'masqueraded' => false
        )
      end

      it 'responds with error' do
        expect(
          claim_voucher.on {|result| result.error(&:message) }
        ).to eq 'A general error has occurred. Please contact the helpdesk if this problem persists.'
      end
    end

    context 'with unknown voucher' do
      let(:voucher_code) { generate(:uuid) }

      it 'responds with error' do
        expect(
          claim_voucher.on {|result| result.error(&:message) }
        ).to eq 'The voucher code you have supplied is not valid. Please check your code.'
      end
    end

    context 'with incompatible product type provided by the client' do
      let(:product_type) { Voucher::ProductTypes.resolve 'proctoring_smowl' }

      it 'responds with error' do
        expect(
          claim_voucher.on {|result| result.error(&:message) }
        ).to eq 'The voucher code you have supplied is not valid for this product.'
      end
    end

    context 'with voucher restricted to a different user' do
      let(:voucher) { create(:voucher, :reactivation, claimant_id: generate(:user_id)) }

      it 'responds with error' do
        expect(
          claim_voucher.on {|result| result.error(&:message) }
        ).to eq 'The voucher code you have supplied is not valid for your user account.'
      end
    end

    context 'with voucher restricted to a different course' do
      let(:voucher) { create(:voucher, :reactivation, course_id: generate(:course_id)) }

      it 'responds with error' do
        expect(
          claim_voucher.on {|result| result.error(&:message) }
        ).to eq 'The voucher code you have supplied is not valid for this course.'
      end
    end

    context 'when already claimed' do
      before do
        voucher.claim!(
          claimant_id: current_user.id,
          claimant_ip: opts[:claimant_ip],
          course_id: course.id
        )
      end

      it 'responds with error' do
        expect(
          claim_voucher.on {|result| result.error(&:message) }
        ).to eq 'The voucher code you have supplied was already used. Codes can only be applied once.'
      end
    end
  end

  context '(product-specific errors)' do
    context 'with the reactivation product' do
      context 'when the product is not available in the course' do
        let(:course) { create(:course, :archived) }

        it 'responds with error' do
          expect(
            claim_voucher.on {|result| result.error(&:message) }
          ).to eq 'Reactivation is not available for this course at this time.'
        end
      end

      context 'when the product is already activated for the user in the course' do
        before do
          create(:enrollment, :reactivated, course:, user_id: current_user.id)
        end

        it 'responds with error' do
          expect(
            claim_voucher.on {|result| result.error(&:message) }
          ).to eq 'You have already reactivated this course.'
        end
      end
    end

    context 'with the proctoring product' do
      let(:voucher) { create(:voucher, :proctoring) }
      let(:product_type) { Voucher::ProductTypes.resolve 'proctoring_smowl' }

      context 'when the product is not available in the course' do
        let(:course) { create(:course, :active) }

        it 'responds with error' do
          expect(
            claim_voucher.on {|result| result.error(&:message) }
          ).to eq 'You cannot book a Certificate for this course.'
        end
      end

      context 'when the product is already activated for the user in the course' do
        let(:course) { create(:course, :active, :offers_proctoring) }

        before do
          create(:enrollment, :proctored, course:, user_id: current_user.id)
        end

        it 'responds with error' do
          expect(
            claim_voucher.on {|result| result.error(&:message) }
          ).to eq 'You already booked a Certificate.'
        end
      end

      context 'when the user is not enrolled in the course' do
        let(:course) { create(:course, :active, :offers_proctoring) }

        it 'responds with error' do
          expect(
            claim_voucher.on {|result| result.error(&:message) }
          ).to eq 'You need to enroll to the course to book a Certificate.'
        end
      end

      context 'when the enrollment has been deleted' do
        let(:course) { create(:course, :active, :offers_proctoring) }

        before do
          create(:enrollment, :deleted, course:, user_id: current_user.id)
        end

        it 'responds with error' do
          expect(
            claim_voucher.on {|result| result.error(&:message) }
          ).to eq 'You need to enroll to the course to book a Certificate.'
        end
      end
    end
  end

  it 'claims the voucher and stores claimant and course' do
    claim_voucher
    voucher.reload
    expect(voucher.claimed?).to be true
    expect(voucher.claimant_id).to eq current_user.id
    expect(voucher.course_id).to eq course.id
  end

  it 'assigns the claimant IP' do
    # Expect change from nil (i.e. '' because of #to_s) to IP
    expect { claim_voucher }.to change { voucher.reload.claimant_ip.to_s }
      .from('').to(opts[:claimant_ip])
  end

  it 'resolves the claimant country' do
    expect { claim_voucher }.to change { voucher.reload.claimant_country }
      .from(nil).to('USA')
  end

  context 'with predefined, i.e. restricted, claimant' do
    let(:voucher) { create(:voucher, :reactivation, claimant_id: current_user.id) }

    it 'claims the voucher' do
      expect { claim_voucher }.to change { voucher.reload.claimed? }
        .from(false).to(true)
    end

    context 'with single-person voucher' do
      let(:voucher) { create(:voucher, :reactivation, claimant_id: current_user.id, tag: 'unique') }

      it 'claims the voucher' do
        expect { claim_voucher }.to change { voucher.reload.claimed? }
          .from(false).to(true)
      end
    end
  end

  context 'with predefined, i.e. restricted, course' do
    let(:voucher) { create(:voucher, :reactivation, course_id: course.id) }

    it 'claims the voucher' do
      expect { claim_voucher }.to change { voucher.reload.claimed? }
        .from(false).to(true)
    end
  end

  context 'with valid but not (!) resolvable claimant IP' do
    let(:opts) { super().merge claimant_ip: '127.0.0.1' }

    it 'sets the user-assigned country code' do
      expect { claim_voucher }.to change { voucher.reload.claimant_country }
        .from(nil).to('AAA')
    end
  end

  context 'with expiry date' do
    let(:expiry_date) { 1.hour.from_now }
    let(:voucher) { create(:voucher, :reactivation, expires_at: expiry_date) }

    it 'claims the voucher' do
      expect { claim_voucher }.to change { voucher.reload.claimed? }
        .from(false).to(true)
    end

    context 'with expiry date passed' do
      let(:expiry_date) { 1.hour.ago }

      it 'responds with error' do
        expect(
          claim_voucher.on {|result| result.error(&:message) }
        ).to eq 'The voucher code you have supplied is already expired.'
      end
    end
  end

  context 'with failure when claiming, i.e. activating, the product' do
    let(:user_id) { generate(:user_id) }

    before do
      Stub.request(
        :course, :post, '/enrollments',
        body: {course_id: course.id, user_id:}
      ).to_return Stub.json({reactivations_url: '/enrollment/1/reactivations'})
      Stub.request(
        :course, :post, '/enrollment/1/reactivations',
        body: hash_including(:submission_date)
      ).to_return Stub.json({errors: {submission_date: 'running'}}, status: 422)
    end

    it 'responds with error' do
      expect(
        claim_voucher.on {|result| result.error(&:message) }
      ).to eq 'A general error has occurred. Please contact the helpdesk if this problem persists.'
    end

    it 'does not claim the voucher nor assign claimant and course' do
      claim_voucher
      voucher.reload
      expect(voucher.claimed?).to be false
      expect(voucher.claimant_id).to be_nil
      expect(voucher.course_id).to be_nil
    end
  end
end

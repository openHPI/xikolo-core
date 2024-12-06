# frozen_string_literal: true

require 'spec_helper'

describe Voucher::ProductTypes::Reactivation do
  subject(:reactivation) { described_class.new(course, user) }

  let(:course) { create(:course, :archived, :offers_reactivation) }
  let(:user) { create(:user) }

  describe '#claim!' do
    subject(:claim) { reactivation.claim! }

    before do
      Stub.service(:course, build(:'course:root'))

      Stub.request(
        :course, :post, '/enrollments',
        body: {course_id: course.id, user_id: user.id}
      ).to_return Stub.json({reactivations_url:})
    end

    let(:reactivations_url) { '/enrollment/0/reactivations' }
    let!(:stub) do
      Stub.request(
        :course, :post, reactivations_url,
        body: hash_including(:submission_date)
      ).to_return Stub.response(status: 201)
    end

    it "reactivates the user's course enrollment" do
      claim
      expect(stub).to have_been_requested
    end

    context 'with an enrollment reactivation error' do
      let!(:stub) do
        Stub.request(
          :course, :post, reactivations_url,
          body: hash_including(:submission_date)
        ).to_return Stub.json({errors: {submission_date: 'running'}}, status: 422)
      end

      it 'raises an error' do
        expect { claim }.to raise_error(Restify::UnprocessableEntity) do
          expect(stub).to have_been_requested
        end
      end
    end
  end
end

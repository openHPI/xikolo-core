# frozen_string_literal: true

require 'spec_helper'

describe Voucher::ProductTypes::Proctoring do
  subject(:proctoring) { described_class.new(course, user) }

  let(:course) { create(:course, :upcoming, :offers_proctoring) }
  let(:user) { create(:user) }

  describe '#claim!' do
    subject(:claim) { proctoring.claim! }

    let!(:stub) do
      Stub.request(
        :course, :post, '/enrollments',
        body: {user_id: user.id, course_id: course.id, proctored: true}
      ).to_return Stub.response(status: 201)
    end

    it 'upgrades the enrollment' do
      claim
      expect(stub).to have_been_requested
    end

    context 'with an error when enabling proctoring' do
      let!(:stub) do
        Stub.request(
          :course, :post, '/enrollments',
          body: {user_id: user.id, course_id: course.id, proctored: true}
        ).to_return Stub.response(status: 422)
      end

      it 'raises an error' do
        expect { claim }.to raise_error(Restify::UnprocessableEntity) do
          expect(stub).to have_been_requested
        end
      end
    end
  end
end

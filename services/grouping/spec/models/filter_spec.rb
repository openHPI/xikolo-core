# frozen_string_literal: true

require 'spec_helper'

describe Filter, type: :model do
  subject { filter.filter(user_id, course_id) }

  let(:filter) { create(:filter) }
  let(:user_id) { SecureRandom.uuid }
  let(:course_id) { SecureRandom.uuid }
  let(:gender) { 'female' }

  before do
    Stub.request(
      :account, :get, "/users/#{user_id}"
    ).to_return Stub.json({
      profile_url: "/users/#{user_id}/profile",
    })

    Stub.request(
      :account, :get, "/users/#{user_id}/profile"
    ).to_return Stub.json({
      fields: [
        {name: 'gender', values: ['female']},
      ],
    })
  end

  context 'invalid filter' do
    subject { filter }

    let(:filter) { described_class.new(field_name: 'gender', operator: '<=', field_value: 'female') }

    it { is_expected.not_to be_valid }
  end

  context 'for female user' do
    it { is_expected.to be true }
  end

  context 'for male user' do
    let(:gender) { 'male' }

    it { is_expected.to be true }
  end

  context 'operator is in' do
    let(:filter) do
      create(:filter, operator: 'in',
        field_value: 'male,female')
    end

    it { is_expected.to be true }
  end

  context 'operator is !=' do
    let(:filter) { create(:filter, operator: '!=') }

    it { is_expected.to be false }
  end

  context 'field_name is enrollments' do
    let(:filter) { create(:enrollments_filter) }

    context 'with less than 1' do
      before do
        Stub.request(
          :course, :get, '/enrollments',
          query: {user_id:}
        ).to_return Stub.json([])
      end

      it { is_expected.to be true }
    end

    context 'with more than 1' do
      before do
        Stub.request(
          :course, :get, '/enrollments',
          query: {user_id:}
        ).to_return Stub.json([{}, {}])
      end

      it { is_expected.to be false }
    end

    context 'operator name is <<' do
      let(:filter) do
        create(:enrollments_filter,
          operator: '<<',
          field_value: '1,3')
      end

      context 'between' do
        before do
          Stub.request(
            :course, :get, '/enrollments',
            query: {user_id:}
          ).to_return Stub.json([{}, {}])
        end

        it { is_expected.to be true }
      end

      context 'not between' do
        before do
          Stub.request(
            :course, :get, '/enrollments',
            query: {user_id:}
          ).to_return Stub.json([{}, {}, {}])
        end

        it { is_expected.to be false }
      end
    end

    context 'operator name is <=<=' do
      let(:filter) do
        create(:enrollments_filter,
          operator: '<=<=',
          field_value: '2,4')
      end

      context 'between' do
        before do
          Stub.request(
            :course, :get, '/enrollments',
            query: {user_id:}
          ).to_return Stub.json([{}, {}])
        end

        it { is_expected.to be true }
      end

      context 'not between' do
        before do
          Stub.request(
            :course, :get, '/enrollments',
            query: {user_id:}
          ).to_return Stub.json([{}])
        end

        it { is_expected.to be false }
      end
    end
  end
end

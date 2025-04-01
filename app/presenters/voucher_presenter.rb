# frozen_string_literal: true

class VoucherPresenter < PrivatePresenter
  attr_reader :claimant, :course

  def self.build(voucher)
    new(voucher:).tap do |presenter|
      presenter.load_claimant!
      presenter.load_course!
    end
  end

  def claimed?
    @voucher.claimed_at.present?
  end

  def code
    @voucher.id
  end

  def tag
    @voucher.tag
  end

  def country
    @voucher.country
  end

  def claimed_at
    @voucher.claimed_at
  end

  def created_at
    @voucher.created_at
  end

  def expires_at
    @voucher.expires_at
  end

  def load_claimant!
    @claimant = if @voucher.claimant_id
                  Xikolo.api(:account).value!.rel(:user).get({id: @voucher.claimant_id}).value!
                end
  end

  def load_course!
    @course = if @voucher.course_id
                Xikolo.api(:course).value!.rel(:course).get({id: @voucher.course_id}).value!
              end
  end
end

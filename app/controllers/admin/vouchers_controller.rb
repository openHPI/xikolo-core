# frozen_string_literal: true

class Admin::VouchersController < Abstract::FrontendController
  before_action do
    raise AbstractController::ActionNotFound unless Xikolo.config.voucher['enabled']
  end
  before_action :load_courses, except: [:stats]

  require_permission 'course.vouchers.issue'

  def index; end

  def create
    Voucher::BatchCreateVouchers.call(
      params[:count], voucher_params
    ).on do |result|
      result.success {|success| @vouchers = success.records }
      result.errors {|errors| @errors = errors }
    end

    render 'index'
  end

  def query
    return if params[:code].blank?

    voucher = Voucher::Voucher.find params[:code]
    @voucher = VoucherPresenter.build(voucher)
  rescue ActiveRecord::RecordNotFound
    add_flash_message :error, t(:'flash.error.voucher.not_found')
  end

  def stats
    @voucher_stats = Voucher::Stats.new
  end

  private

  def voucher_params
    @voucher_params ||= params.permit(:tag, :claimant_id, :course_id, :expires_at, :product_type)
      .merge(country: 'de')
  end

  def load_courses
    @courses = Course::Course.not_deleted.order(:course_code)
  end
end

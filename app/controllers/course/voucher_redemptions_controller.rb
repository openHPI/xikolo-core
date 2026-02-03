# frozen_string_literal: true

module Course
  class VoucherRedemptionsController < Abstract::FrontendController
    before_action do
      raise AbstractController::ActionNotFound unless Xikolo.config.voucher['enabled']
    end

    before_action :ensure_logged_in
    before_action :ensure_product_prerequisites
    before_action :set_no_cache_headers

    layout 'simple'

    def new
      render locals: {
        form: VoucherRedemptionForm.new,
        course:,
        product: product_type,
      }
    end

    def create
      Voucher::Claim.call(
        params[:voucher_redemption][:code].strip,
        product_type,
        course,
        current_user,
        claimant_ip: request.remote_ip
      ).on do |result|
        result.success do |s|
          add_flash_message :success, s.message
          redirect_to course_path(course.course_code)
        end
        result.error do |e|
          add_flash_message :error, e.message
          render action: :new, locals: {
            form: VoucherRedemptionForm.from_resource(
              'code' => params[:voucher_redemption][:code].strip
            ),
            course:,
            product: product_type,
          }, status: :unprocessable_entity
        end
      end
    end

    private

    def product_type
      @product_type ||= Voucher::ProductTypes.resolve(params[:product])
    rescue KeyError
      # If the product type for the requested product cannot
      # be resolved, a `KeyError` will be raised.
      raise Status::NotFound
    end

    ##
    # Fail early if the product prerequisites are not met.
    # In this case, don't show the voucher redemption form at all nor
    # try redeeming the voucher.
    #
    def ensure_product_prerequisites
      return if product_type.enabled_in?(course)

      add_flash_message :error, product_type.unavailable_message
      redirect_to course_path(course.course_code)
    end

    def course
      @course ||= ::Course::Course.by_identifier(params[:course_id]).take!
    rescue ActiveRecord::RecordNotFound
      raise Status::NotFound
    end

    def auth_context
      course.context_id
    end
  end
end

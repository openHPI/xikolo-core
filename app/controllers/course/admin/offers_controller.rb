# frozen_string_literal: true

class Course::Admin::OffersController < Abstract::FrontendController
  include CourseContextHelper

  inside_course
  require_permission 'course.course.edit'

  def index
    @course = Course::Course.by_identifier(params[:course_id]).take
    @offers = @course.offers
  end

  def new
    @course = Course::Course.by_identifier(params[:course_id]).take
    @offer = @course.offers.new
  end

  def edit
    @course = Course::Course.by_identifier(params[:course_id]).take
    @offer = Course::Offer.find(params[:id])
  end

  def create
    @course = Course::Course.by_identifier(params[:course_id]).take
    @offer = Course::Offer.new(
      offer_params.merge(course_id: @course.id, price:)
    )

    if @offer.save
      add_flash_message :success, t(:'flash.success.offer_created')
      redirect_to course_offers_path, status: :see_other
    else
      add_flash_message :error, t(:'flash.error.offer_not_created')
      render :new, status: :unprocessable_entity
    end
  end

  def update
    @course = Course::Course.by_identifier(params[:course_id]).take
    @offer = Course::Offer.find(params[:id]).tap do |offer|
      offer.assign_attributes(
        offer_params.merge(course_id: @course.id, price:)
      )
    end

    if @offer.save
      add_flash_message :success, t(:'flash.success.offer_updated')
      redirect_to course_offers_path, status: :see_other
    else
      add_flash_message :error, t(:'flash.error.offer_not_updated')
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if Course::Offer.find(params[:id]).destroy
      add_flash_message :success, t(:'flash.success.offer_deleted')
    else
      add_flash_message :error, t(:'flash.error.offer_not_deleted')
    end

    redirect_to course_offers_path, status: :see_other
  end

  private

  def auth_context
    the_course.context_id
  end

  def offer_params
    params.require(:course_offer).permit(
      :price_currency,
      :payment_frequency,
      :category
    )
  end

  def price
    price = params.dig(:course_offer, :price)
    raise ArgumentError.new('Invalid price') if price.blank?

    (price.to_d * BigDecimal(100)).to_i
  end

  def hide_course_nav?
    true
  end
end

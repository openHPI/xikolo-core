# frozen_string_literal: true

class API::TreatmentsController < API::RESTController
  respond_to :json

  def index
    respond_with Treatment.order(required: :desc, created_at: :asc)
  end

  def create
    respond_with Treatment.create(treatment_params), status: :created
  end

  def show
    respond_with resource
  end

  def update
    respond_with resource, status: :forbidden
  end

  private

  def treatment_params
    params.permit(:name)
  end
end

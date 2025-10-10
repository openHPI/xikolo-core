# frozen_string_literal: true

module AccountService
class API::ConsentsController < API::RESTController # rubocop:disable Layout/IndentationWidth
  respond_to :json

  def index
    respond_with resources.list.map(&:decorate)
  end

  def merge
    ActiveRecord::Base.transaction do
      consents = resources.list

      consents.each do |consent|
        change = changes.find do |r|
          (r[:id].blank? || r[:id] == consent.treatment.id) &&
            (r[:name].blank? || r[:name] == consent.treatment.name)
        end

        next unless change&.key?(:consented)

        consent.update!(value: change[:consented])
      end

      respond_with consents.map(&:decorate), location: false
    end
  end

  def show
    respond_with resource
  end

  def destroy
    respond_with resource.destroy!
  end

  private

  def json
    params.permit(_json: %i[id name consented]).fetch(:_json, [])
  end

  # All change sets that identify a consent by id or name
  def changes
    @changes ||= Array(json).reject {|r| r[:id].blank? && r[:name].blank? }
  end

  def user
    @user ||= User.resolve(params[:user_id])
  end

  def resources
    Consent.where(user_id: params[:user_id])
  end

  def resource
    resources.where(treatment_id: params[:id]).take!
  end
end
end

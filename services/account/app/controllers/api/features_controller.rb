# frozen_string_literal: true

class API::FeaturesController < API::RESTController
  respond_to :json

  rfc6570_params index: [:context]

  def index
    respond_with \
      Feature.lookup(owner:, context:),
      location: false
  end

  def update
    json = JSON.parse request.body.string

    Feature::Update.new(owner, context).call json

    index
  rescue ActiveRecord::RecordInvalid => e
    respond_with e.record
  end

  def destroy
    return head(:not_found, content_type: 'text/plain') if params[:name].blank?

    feature = Feature
      .where(owner:, context:, name: params[:name])
      .take!

    feature.destroy!

    head :no_content
  end

  private

  def owner
    if params.key? :group_id
      Group.resolve params.fetch :group_id
    else
      User.resolve params.fetch :user_id
    end
  end

  def context
    if params.key? :context
      Context.resolve params.fetch :context
    else
      Context.root
    end
  end
end

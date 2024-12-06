# frozen_string_literal: true

class API::ProfilesController < API::RESTController
  respond_to :json

  def show
    respond_with ProfileDecorator.new fields, user
  end

  def update
    ActiveRecord::Base.transaction do
      fields = params[:fields].map do |payload|
        CustomField
          .find(payload[:id])
          .update_values(user, payload[:values])
      end

      user.update_profile_completion!

      presenter = ProfileDecorator.new fields, user
      respond_with presenter, location: user_profile_url(user)

      Msgr.publish(presenter.as_event, to: 'xikolo.account.profile.update')
    end
  rescue ActiveRecord::RecordInvalid => e
    render formats.first => {errors: e.record.errors},
      status: :unprocessable_entity
  end

  def fields
    CustomField.context 'user'
  end

  def user
    User.find params[:user_id]
  end
end

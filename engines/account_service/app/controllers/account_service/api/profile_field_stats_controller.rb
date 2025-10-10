# frozen_string_literal: true

module AccountService
class API::ProfileFieldStatsController < API::BaseController # rubocop:disable Layout/IndentationWidth
  responders \
    ::Responders::DecorateResponder,
    ::Responders::HttpCacheResponder,
    ::Responders::PaginateResponder

  respond_to :json

  def show
    expires_in 1.hour, public: true

    respond_with field
  end

  def decoration_context
    {histograms: CustomFieldValue.for_members_of(group).histograms(field)}
  end

  private

  def group
    Group.resolve(params[:group_id])
  end

  def field
    return @field if defined?(@field)

    @field = CustomField.find_by name: params[:id]
  end
end
end

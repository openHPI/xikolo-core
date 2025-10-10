# frozen_string_literal: true

module AccountService
class API::GroupStatsController < API::BaseController # rubocop:disable Layout/IndentationWidth
  responders \
    ::Responders::DecorateResponder,
    ::Responders::HttpCacheResponder,
    ::Responders::PaginateResponder

  respond_to :json

  def show
    expires_in 1.hour, public: true

    stats = {
      members: member_count,
    }

    if embed?('affiliated')
      stats['affiliated_members'] = affiliated_member_count
    end

    stats['profile'] = profile_stats if embed?('profile')

    if embed?('user')
      stats['user'] = {
        age: user_stats,
      }
    end

    respond_with stats
  end

  private

  def group
    Group.resolve(params[:group_id])
  end

  def embed?(section)
    embed.include?(section)
  end

  def embed
    @embed ||= params[:embed].to_s.split(',')
  end

  def member_count
    group.members.count
  end

  def affiliated_member_count
    group.members.where(affiliated: true).count
  end

  def profile_stats
    CustomFieldDecorator.decorate_collection(
      profile_fields,
      context: {histograms:}
    )
  end

  def histograms
    @histograms ||= CustomFieldValue.for_members_of(group).histograms
  end

  def profile_fields
    histograms.keys
  end

  def user_stats
    group.members
      .unscope(:order)
      .where.not(born_at: nil)
      .group('extract(year from age(born_at))::integer')
      .pluck(
        Arel.sql('extract(year from age(born_at))::integer'),
        Arel.sql('COUNT(*)')
      ).to_h
  end
end
end

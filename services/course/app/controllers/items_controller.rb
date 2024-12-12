# frozen_string_literal: true

class ItemsController < ApplicationController
  responders Responders::ApiResponder,
    Responders::DecorateResponder,
    Responders::HttpCacheResponder,
    Responders::PaginateResponder
  include PointsProcessor

  respond_to :json

  def index
    items = Item.all
    items.where! content_type: params[:content_type] if params[:content_type]
    if params[:exercise_type]
      case params[:exercise_type]
        when ::ActionController::Parameters
          items.where! exercise_type: params[:exercise_type].values
        when String
          items.where! exercise_type: params[:exercise_type].split(',')
        else
          items.where! exercise_type: params[:exercise_type]
      end
    end
    items.where! section_id: params[:section_id] unless params[:section_id].nil?
    items.where! content_id: params[:content_id] unless params[:content_id].nil?
    items.where! id: params[:id] unless params[:id].nil?
    # NOTE: This will also return available items from an unavailable section:
    items = items.available unless params[:available].nil?
    # This one respects the availability of sections:
    items = items.all_available unless params[:all_available].nil?
    items = items.was_available unless params[:was_available].nil?
    items.where! published: params[:published] unless params[:published].nil?
    if params[:course_id].present?
      sections = Section.where(course_id: params[:course_id])
        .select('id')
      if params[:available] == 'true' || params[:first_available]
        sections = sections.available
      end
      sections = sections.was_available if params[:was_available].present?
      items = items.where(section_id: sections)
      items = items.course_order
    end
    items = items.where featured: true if params[:featured]
    if params[:open_mode]
      return respond_with items.none unless params[:course_id]

      course = Course.find(params[:course_id])
      items = if course.accessible?
                items.all_available.open_mode
              else
                items.none
              end
    end

    # TODO: this should actually only drop items, where the requirements are not fulfilled.
    # This will however not be feasible until course and quiz move to the monolith.
    if params[:required_items] == 'none'
      items = items.where(required_item_ids: [])
    end

    items = items.user_state params[:state_for] if params[:state_for].present?

    if params[:proctored].present?
      items = items.where proctored: params[:proctored]
    end

    items.includes! section: :course

    if embed.include?('user_visit') && params[:user_id].present?
      items = items.with_user_visit(params[:user_id])
    end

    if params[:user_id].present? || params[:state_for].present?
      user_id = params[:user_id].presence || params[:state_for].presence

      if params[:section_id].present?
        section = Section.find_by(id: params[:section_id])
        if section&.course&.node.present?
          items = Structure::UserItemsSelector.new(section.node, user_id).items(scope: items)
          decoration_context[:position_from_tree] = true
        end
      elsif params[:course_id].present?
        course = Course.find_by(id: params[:course_id])
        if course&.node.present?
          items = Structure::UserItemsSelector.new(course.node, user_id).items(scope: items)
          decoration_context[:position_from_tree] = true
        end
      end
    end

    items = items.new_for params[:new_for] if params[:new_for]

    respond_with items, embed:
  end

  rfc6570_params show: %i[embed user_id version_at for_user]
  def show
    item = Item.find params[:id]

    decoration_context[:position_from_tree] = !item.section.course.legacy?

    if (params[:user_id].present? || params[:for_user].present?) &&
       !item.accessible_for(user_id: params[:user_id].presence || params[:for_user])
      return head(:not_found, content_type: 'text/plain')
    end

    if embed.include?('user_visit') && params[:user_id].present?
      item = Item.with_user_visit(params[:user_id]).find params[:id]
    end

    if params[:version_at].present?
      item = item.paper_trail.version_at(Time.zone.parse(params[:version_at]))
      if item.nil?
        return render status: :not_found, json: {reason: 'none_existing_version'}
      end
    end

    item.for_user! params[:for_user] if params[:for_user].present?

    respond_with item, embed:
  end

  def current
    unless params[:user].present? && params[:course].present?
      return error 422, message: 'user and course needed'
    end

    if user_enrolled?
      last_visit = Visit.latest_for(user: params[:user], items: available_items.ids).take

      if last_visit.present?
        return respond_with last_visit.item
      end
    end

    items = available_items.limit(1).to_ary
    if items.empty?
      return render status: :not_found, json: {reason: 'not_public_item'}
    end

    respond_with items.first
  end

  def create
    item = Item.create item_params
    item.move_to_bottom
    fix_errors item, :max_dpoints, :max_points
    respond_with item
  end

  def update
    item = Item.find(params[:id])
    item.update(item_params)
    fix_errors item, :max_dpoints, :max_points
    respond_with item
  end

  def destroy
    item = Item.find(params[:id])
    respond_with item.destroy
  end

  def max_per_page
    1000 # should be more than existing items within course
  end

  def per_page
    # allow to fetch all items of a course per default:
    params[:per_page].try(:to_i) || max_per_page
  end

  def decoration_context
    @decoration_context ||= {
      collection: action_name == 'index',
      raw: params[:raw],
      user_id: params[:user_id].presence || params[:for_user],
    }
  end

  private

  def item_params
    permitted_params = params.permit(
      :id,
      :title,
      :position,
      :start_date,
      :end_date,
      :content_type,
      :content_id,
      :section_id,
      :published,
      :show_in_nav,
      :format,
      :exercise_type,
      :submission_deadline,
      :submission_publishing_date,
      :proctored,
      :optional,
      :icon_type,
      :featured,
      :public_description,
      :open_mode,
      :time_effort,
      required_item_ids: []
    )
    permitted_params = permitted_params.except :format
    if params.key?(:max_points)
      permitted_params[:max_dpoints] = parse_points(:max_points)
    end
    if permitted_params[:proctored].nil?
      permitted_params = permitted_params.except :proctored
    end
    permitted_params
  end

  def embed
    @embed ||= params[:embed].to_s.split(',').map(&:strip)
  end

  def available_items
    if params[:preview] == 'true'
      items = course.items
    elsif user_enrolled?
      items = course.items.all_available
    else
      # Anonymous users and not enrolled users only get to see open mode items
      items = course.items.all_available.open_mode
    end

    items = items.course_order

    unless course.legacy?
      items = Structure::UserItemsSelector.new(course.node, params[:user]).items(scope: items)
    end

    items
  end

  def user_enrolled?
    return false if params[:user] == 'anonymous'

    course.enrollments.active.find_by(user_id: params[:user])
  end

  def course
    @course ||= Course.by_identifier(params[:course]).take
  end
end

# frozen_string_literal: true

class Admin::PollsController < Abstract::FrontendController
  before_action :set_no_cache_headers
  before_action :ensure_logged_in

  require_permission 'helpdesk.polls.manage'

  def index
    # TODO: Implement pagination
    @polls = Poll::Poll.all.latest_first
  end

  def new
    @poll = Poll::Poll.new
  end

  def edit
    @poll = Poll::Poll.find(params[:id])
  end

  def create
    @poll = Poll::Poll.new poll_params
    if @poll.save
      add_flash_message :success, t(:'flash.success.poll_created')
      redirect_to edit_admin_poll_path(id: @poll.id)
    else
      add_flash_message :error, t(:'flash.error.poll_not_created')
      render :new
    end
  end

  def update
    @poll = Poll::Poll.find(params[:id])
    if @poll.update(poll_params)
      add_flash_message :success, t(:'flash.success.poll_updated')
      redirect_to admin_polls_path
    else
      add_flash_message :error, t(:'flash.error.poll_not_updated')
      render :edit
    end
  end

  def destroy
    poll = Poll::Poll.find params[:id]
    if poll.destroy
      add_flash_message :success, t(:'flash.success.poll_deleted')
    else
      add_flash_message :error, t(:'flash.success.poll_not_deleted')
    end

    redirect_to admin_polls_path
  end

  private

  def poll_params
    params.require(:poll).permit(
      :question,
      :start_at,
      :end_at,
      :allow_multiple_choices,
      :show_intermediate_results
    )
  end
end

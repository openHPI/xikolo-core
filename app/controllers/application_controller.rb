# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include Login

  protect_from_forgery with: :exception
  before_action { Acfs.runner.clear } # clear Acfs queue

  include Locale

  before_action :forget_location, if: proc {|_| current_user.anonymous? }
  before_action :redirect_expired_sessions

  add_flash_types :error, :success

  include Status # specific error classes and handling

  def add_flash_message(type, message)
    (flash[type] ||= Set.new) << message
  end

  def redirect_to(options = {}, response_status = {})
    (%i[error notice alert success] & response_status.keys).each do |type|
      add_flash_message type, response_status.delete(type)
    end

    super
  end

  # Use this method when explicitly redirecting to an external URL that
  # might have a different hostname. This makes bypassing the same-host
  # protection of `#redirect_to` explicit.
  def redirect_external(*, **)
    redirect_to(*, **, allow_other_host: true)
  end

  protected

  # Before helper to ensure privileges!
  def ensure_logged_in
    return true if current_user.logged_in?

    store_location
    unless Login.external?
      add_flash_message :error, t(:'flash.error.login_to_proceed')
    end

    redirect_external login_url
    false
  end

  def ensure_content_editor
    return unless ensure_logged_in
    return if current_user.allowed?('course.content.edit')

    add_flash_message :error, t(:'flash.error.not_authorized')
    redirect_to root_url, status: :see_other
  end

  def authorize!(permission)
    return if current_user.allowed?(permission)

    raise Status::Unauthorized.new("User does not have permission #{permission}.")
  end

  def authorize_any!(*permissions)
    return if current_user.allowed_any?(*permissions)

    raise Status::Unauthorized.new("User does not have any of the permissions #{permissions.join(', ')}.")
  end

  def store_location(path = request.fullpath, forget: false)
    return unless request.get? || path != request.fullpath
    return if request.xhr?

    cookies.signed[:stored_location] = path
    cookies.signed[:forget_location] = true if forget
  end

  def forget_location
    if cookies.signed[:forget_location] && !request.fullpath.start_with?('/auth/')
      cookies.delete :stored_location if cookies.signed[:stored_location]
      cookies.delete :forget_location
    end
  end

  def redirect_url
    return dashboard_url if cookies.signed[:stored_location].blank?

    stored_path = cookies.signed[:stored_location]
    cookies.delete :stored_location
    URI.join(request.base_url, stored_path).to_s
  end

  def promises
    @promises ||= {}
  end

  helper_method :promises

  def short_uuid(id)
    UUID(id).to_param
  end

  class << self
    def require_user(opts = {})
      before_action :ensure_logged_in, opts
    end

    def require_permission(name, opts = {})
      before_action(opts) { authorize! name }
    end

    ##
    # Disable the controller if the given feature flipper is disabled.
    #
    # Controllers where all or some of the actions are dependent on features
    # being enabled, can use this to respond with HTTP 404 responses.
    #
    def require_feature(name, opts = {})
      before_action(opts) do
        raise AbstractController::ActionNotFound unless current_user.feature?(name)
      end
    end
  end

  def the_course
    @the_course ||= request_course
  rescue ActiveRecord::RecordNotFound
    raise Status::NotFound
  end

  def current_user
    @current_user ||= if current_session
                        CurrentUser::User.new(session: current_session, context_id: auth_context)
                      else
                        CurrentUser::AnonymousUser.new(context_id: auth_context)
                      end
  end
  helper_method :current_user

  def redirect_expired_sessions
    return unless current_user.anonymous? && current_session_id

    reset_session
    add_flash_message :error, t(:'flash.error.session_expired')
    raise Status::Redirect.new 'Session expired', root_url
  end

  # In which context are we? For which context do we need to know which
  # permissions and features the user has?
  def auth_context
    :root
  end

  def current_session
    return unless current_session_id

    @current_session ||= AccountService::Session.find_by(id: session[:id])
      .tap { it&.access! }
  end

  def current_session_id
    return if session[:id] == 'anonymous'

    session[:id]
  end

  # Promise compatible interface for newer Acfs version
  # will be ported to the Acfs::Promise if awailable
  class PromiseFulfiller
    def initialize(promise)
      @promise = promise
    end

    def fulfill(obj)
      @promise.__fulfill__ obj
    end
  end

  class ResourceDelegator < Acfs::Util::ResourceDelegator
    def loaded?
      @loaded
    end

    def loaded!
      @loaded = true
    end

    def __invoke__
      loaded!
      super
    end

    def __fulfill__(obj)
      __setobj__ obj
      __invoke__
    end
  end

  def create_promise(obj_until_fulfilled = nil)
    promise = ResourceDelegator.new obj_until_fulfilled
    [promise, PromiseFulfiller.new(promise)]
  end

  def dummy_resource_delegator(obj)
    m = ResourceDelegator.new obj
    m.__fulfill__ obj
    m
  end
end

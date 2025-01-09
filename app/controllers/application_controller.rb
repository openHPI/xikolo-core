# frozen_string_literal: true

class ApplicationController < ActionController::Base
  # Make the FeatureTogglesHelper available in views as well as controllers
  helper FeatureTogglesHelper
  include FeatureTogglesHelper

  include UserTestsHelper
  include Login

  protect_from_forgery with: :exception
  before_action { Acfs.runner.clear } # clear Acfs queue
  around_action :auth_middleware
  after_action  :remember_user

  include Locale

  before_action :forget_location, if: proc {|_| current_user.anonymous? }

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

    redirect_to login_url
    false
  end

  def ensure_content_editor
    return unless ensure_logged_in
    return if current_user.allowed?('course.content.edit')

    add_flash_message :error, t(:'flash.error.not_authorized')
    redirect_to root_url
  end

  def authorize!(permission)
    return if current_user.allowed?(permission)

    raise Status::Unauthorized.new("User does not have permission #{permission}.")
  end

  def authorize_any!(*permissions)
    return if current_user.allowed_any?(*permissions)

    raise Status::Unauthorized.new("User does not have any of the permissions #{permissions.join(', ')}.")
  end

  def set_no_cache_headers
    response.headers['Cache-Control'] = 'no-cache, no-store, max-age=0, must-revalidate'
    response.headers['Pragma'] = 'no-cache'
    response.headers['Expires'] = 'Fri, 01 Jan 1990 00:00:00 GMT'
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
    # Disable the controller for brands other than the given one.
    #
    def require_brand(name, opts = {})
      before_action(opts) do
        raise AbstractController::ActionNotFound unless Xikolo.brand == name
      end
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

  def auth_middleware(&app)
    request.env['xikolo_context'] = auth_context

    Xikolo::Common::Auth::Middleware.new(app).call(request.env)
  end

  # For sessions initiated by tokens in the Authorization header
  # (as used by mobile apps), we remember them for subsequent
  # requests by storing the session ID in a cookie
  def remember_user
    return if current_user.anonymous?

    # If there is already another session ID in cookie storage,
    # we will not override that one
    return if session[:id]

    # If we get here, create a new session for the authenticated user
    session[:id] = Xikolo.api(:account).value!.rel(:sessions).post(
      user: current_user.id
    ).value!['id']
  end

  def the_course
    promises[:course] ||= request_course.tap { Acfs.run }
  rescue Acfs::ResourceNotFound
    raise Status::NotFound
  end

  def current_user
    @current_user ||= if request.env['current_user']
                        request.env['current_user'].value!
                      else
                        Xikolo::Common::Auth::CurrentUser.from_session(
                          'user' => {
                            'anonymous' => true,
                            'language' => I18n.locale,
                            'preferred_language' => nil,
                          }
                        )
                      end
  rescue Restify::NotFound
    # If we get a 404 error here, we assume that this means the session has expired
    reset_session
    add_flash_message :error, t(:'flash.error.session_expired')
    raise Status::Redirect.new 'Session expired', root_url
  end
  helper_method :current_user

  # In which context are we? For which context do we need to know which
  # permissions and features the user has?
  def auth_context
    :root
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

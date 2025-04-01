# frozen_string_literal: true

class Account::ProfilesController < Abstract::FrontendController
  include Xikolo::Account

  require_feature 'profile'
  before_action :ensure_logged_in
  include Interruptible

  USER_KEYS = %i[full_name display_name born_at].freeze

  def show
    user = find_user
    @profile = Account::ProfilePresenter.new(user, native_login: current_user.feature?('account.login'))
    Acfs.run

    set_page_title t(:'header.navigation.profile')
    render layout: 'dashboard'
  end

  def update
    if user_params.any?
      update_user
    elsif params[:email].present?
      update_email
    elsif params.key?(:name) && params.key?(:value)
      update_profile
    end
  rescue Acfs::InvalidResource => e
    # This is an ACFS error object, not Rails:
    # rubocop:disable Rails/DeprecatedActiveModelErrorsMethods
    render status: :unprocessable_entity, plain: e.errors.values.flatten.join(', ')
    # rubocop:enable Rails/DeprecatedActiveModelErrorsMethods
  end

  def update_user
    user = find_user

    user.update_attributes!(user_params)

    render json: {
      status: 'ok',
      user: {
        full_name: user.full_name,
        name: user.name,
        display_name: user.display_name,
        born_at: user.born_at,
      }.transform_values {|val| ERB::Util.html_escape(val) },
    }
  end

  def update_email
    email = Email.create! user_id: current_user.id, address: params[:email]

    verifier = ::Account::ConfirmationsController.verifier
    payload = verifier.generate(email.id.to_s)

    Msgr.publish({
      user_id: current_user.id,
      id: email.id,
      url: account_confirmation_url(payload),
    }, to: 'xikolo.account.email.confirm')

    add_flash_message :notice, t(:'flash.notice.confirmation_email_required', email: email.address)
    render json: {status: 'ok', email: current_user.email}
  end

  def unsuspend_primary_email
    user  = Xikolo.api(:account).value!.rel(:user).get({id: current_user.id}).value!
    email = user.rel(:emails).get.value!
      .find {|e| e[:primary] }
    email.rel(:suspension).delete.value!

    add_flash_message :success, t(:'flash.success.primary_email_unsuspended')
    redirect_to profile_path
  end

  def delete_authorization
    Authorization.find params[:id] do |auth|
      if auth.user_id == current_user.id
        auth.delete
        add_flash_message :notice, t(:'flash.notice.auth_deleted')
      else
        add_flash_message :error, t(:'flash.error.auth_delete_failed')
      end
    end
    Acfs.run

    redirect_to profile_path
  end

  def delete_email
    email = Email.find params[:id], params: {user_id: current_user.id}
    begin
      Acfs.run
    rescue Acfs::ResourceNotFound
      # it's already gone
      return redirect_to profile_path
    end

    email.delete

    redirect_to profile_path
  end

  def change_primary_email
    Email.find params[:id], params: {user_id: current_user.id} do |e|
      e.update_attributes({primary: true})
    end

    Acfs.run

    redirect_to profile_path
  end

  def update_profile
    profile = Profile.find user_id: current_user.id
    Acfs.run

    if params[:value].is_a?(Array)
      profile.fields[params[:name]].values = params[:value]
    else
      profile.fields[params[:name]].value = params[:value]
    end
    profile.save!

    render json: {status: 'ok', params[:name] => profile.fields[params[:name]].value}
  end

  def update_visual
    if params[:visual]
      uuid = UUID4.new.to_s
      filename = params[:visual].original_filename.gsub(/[^-a-zA-Z0-9_.]+/, '_')
      bucket = Xikolo::S3.bucket_for(:uploads)
      bucket.put_object(
        key: "uploads/#{uuid}/#{filename}",
        body: params[:visual],
        acl: 'private',
        metadata: {
          'xikolo-purpose' => 'account_user_avatar',
          'xikolo-state' => 'accepted',
        }
      )

      user = find_user
      user.update_attributes!({avatar_upload_id: uuid})
    end

    redirect_to dashboard_profile_path
  rescue => e
    ::Mnemosyne.attach_error(e)
    ::Sentry.capture_exception(e)

    redirect_to dashboard_profile_path,
      error: t(:'flash.error.picture_not_uploaded')
  end

  def change_my_password
    Account::ChangePassword.call(
      current_user, password_params
    ).on do |result|
      result.success { add_flash_message :notice, t(:'flash.notice.password_changed') }
      result.error {|e| add_flash_message :error, e.message }
    end

    redirect_to dashboard_profile_path
  end

  private

  def user_params
    params.permit(*USER_KEYS).to_h.tap do |p|
      p[:full_name] = p[:full_name].squish if p[:full_name]
      p[:display_name] = p[:display_name].squish if p[:display_name]
    end
  end

  def password_params
    params.require(:xikolo_account_user).permit :old_password, :new_password, :password_confirmation
  end

  def find_user
    user = User.find current_user.id
    Acfs.run

    user
  end
end

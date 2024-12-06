# frozen_string_literal: true

# Checks whether the current session should be interrupted and redirects away
#
# Interrupts can be necessary when xi-account determines that important
# information is missing from the user. This can be things like consents,
# mandatory profile fields, security information etc.
#
# When an interrupt is necessary (and allowed by including this concern), the
# user is redirected away. Once the information has been provided, they can use
# the stored redirect target to get the user back to their previous location.
#
# To prevent unwanted side effects, only safe web requests (HTTP GET, but not
# from mobile apps or via AJAX) are interrupted.
module Interruptible
  extend ActiveSupport::Concern

  ##
  # The list of supported interrupts, as exposed by xi-account
  #
  # Please note that these are ordered by priority. The location hash is used
  # to prevent a redirect loop when the user is already visiting the URL that
  # is also the interrupt's target.
  INTERRUPT_LOCATIONS = {
    'new_consents' => {controller: 'account/treatments', action: 'index'},
    'new_policy' => {controller: 'account/policies', action: 'show'},
    'mandatory_profile_fields' => {controller: 'account/profiles', action: 'show'},
  }.freeze

  included do
    before_action :check_interrupts!
  end

  private

  def check_interrupts!
    return unless interruptible_request?
    return if known_interrupts.none?

    location = INTERRUPT_LOCATIONS[known_interrupts.first]

    if location.any? {|k, v| params[k] != v }
      flash_message = I18n.t("interrupts.#{known_interrupts.first}", default: '')
      add_flash_message :alert, flash_message if flash_message.present?

      store_location(request.fullpath)
      redirect_to location, status: :see_other
    end
  end

  def known_interrupts
    @known_interrupts ||= INTERRUPT_LOCATIONS.keys & current_user.interrupts.select do |i|
      i != 'mandatory_profile_fields' || current_user.feature?('profile')
    end
  end

  def interruptible_request?
    return false unless current_user.logged_in?
    return false unless request.get?
    return false if request.xml_http_request?
    return false if request.params['in_app'] == 'true'

    true
  end
end

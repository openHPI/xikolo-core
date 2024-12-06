# frozen_string_literal: true

# Be sure to restart your server when you modify this file.

# Add new inflection rules using the following format. Inflections
# are locale specific, and you may define rules for as many different
# locales as you wish. All of these examples are active by default:
ActiveSupport::Inflector.inflections(:en) do |inflect|
  #   inflect.plural /^(ox)$/i, '\1en'
  #   inflect.singular /^(ox)en/i, '\1'
  #   inflect.irregular 'person', 'people'
  inflect.uncountable %w[progress]
end

ActiveSupport::Inflector.inflections do |inflect|
  inflect.acronym 'API'
  inflect.acronym 'EGovCampus'
  inflect.acronym 'HPI'
  inflect.acronym 'ID'
  inflect.acronym 'IP'
  inflect.acronym 'JSON'
  inflect.acronym 'KICampus'
  inflect.acronym 'MeinBildungsraum'
  inflect.acronym 'OmniAuth'
  inflect.acronym 'OpenSAP'
  inflect.acronym 'REST'
  inflect.acronym 'RESTful'
  inflect.acronym 'SAML'
  inflect.acronym 'SAP'
  inflect.acronym 'URI'
  inflect.acronym 'URL'
  inflect.acronym 'UUID'
  inflect.acronym 'WHO'
  inflect.acronym 'XUI'
  inflect.uncountable 'metadata'
end

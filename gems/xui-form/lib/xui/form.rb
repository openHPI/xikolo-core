# frozen_string_literal: true

require 'active_model'
require 'active_model/type/hash'
require 'active_model/type/list'
require 'active_model/type/markup'
require 'active_model/type/new_upload'
require 'active_model/type/single_line_string'
require 'active_model/type/subform'
require 'active_model/type/text'
require 'active_model/type/uri'
require 'active_model/type/uuid'
require 'active_model/type/upload'
require 'active_model/type/xikolo_string'

module XUI
  class Form
    require 'xui/form/attribute_type'
    require 'xui/form/dynamic_attributes'
    require 'xui/form/errors'
    require 'xui/form/hash_fields'
    require 'xui/form/naming'
    require 'xui/form/persistence'
    require 'xui/form/processors'
    require 'xui/form/type_extension'

    include ActiveModel::Model
    include ActiveModel::Attributes

    include AttributeType
    include DynamicAttributes
    include Errors
    include HashFields
    include Persistence
    include Processors
    extend Naming
    extend TypeExtension
  end
end

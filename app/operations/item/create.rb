# frozen_string_literal: true

class Item::Create < ApplicationOperation
  def initialize(item:, content:, section:)
    super()

    @item = item
    @content = content
    @section = section
  end

  def call
    # Ensure the content resource is valid.
    raise ContentCreationError.new({base: ['invalid']}) unless @content.valid?
    # The section ID needs to be set for the item; abort early if it is missing.
    raise ArgumentError.new('section_required') if @section['id'].blank?

    # Create the content resource; will raise a ContentCreationError
    # if it cannot be created.
    create_content_resource!

    # Set required item attributes (e.g., content resource relation)
    # and create the item resource; will raise an ItemCreationError
    # if it cannot be created. In case of an Acfs::InvalidResource
    # the content resource will be deleted right away.
    @item.content_id = @content.id
    @item.section_id = @section['id']
    create_item_resource!

    # Create implicit tags for the item
    create_pinboard_tags!

    @item
  rescue ArgumentError => e
    @item.errors.add(:base, I18n.t(:".errors.messages.item.base.#{e.message}"))
    @item
  rescue ItemCreationError
    @content.respond_to?(:destroy) ? @content.destroy : @content.delete
    @item
  rescue Acfs::ErroneousResponse
    # In case the item resource could not be created and the content resource
    # has not been deleted yet, do it now and add an error, which can be
    # handled in the frontend.
    @content.respond_to?(:destroy) ? @content.destroy : @content.delete
    @item.errors.add(:base, I18n.t(:'.errors.messages.item.base.could_not_be_created'))
    @item
  end

  class ContentCreationError < StandardError
    attr_reader :errors

    def initialize(errors)
      @errors = errors
      super('Content creation failed')
    end
  end

  class ItemCreationError < StandardError; end

  private

  def create_content_resource!
    @content.save!
  rescue Restify::ClientError, Acfs::InvalidResource => e
    raise ContentCreationError.new(e.errors)
  rescue Acfs::ErroneousResponse
    raise ContentCreationError.new({base: ['failed']})
  end

  def create_item_resource!
    @item.save!
  rescue Acfs::InvalidResource
    # Roll back the item content resource if the item cannot be created
    # due to Acfs::InvalidResource (will add the errors to the item resource)
    raise ItemCreationError.new('failed')
  end

  def create_pinboard_tags!
    Xikolo::Pinboard::ImplicitTag.create(
      name: @item.id,
      course_id: @section['course_id'],
      referenced_resource: 'Xikolo::Course::Item'
    )
    Acfs.run
  end
end

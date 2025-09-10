# frozen_string_literal: true

class FeaturedItemPresenter
  def self.build(item, course)
    if item.content_type != 'video'
      raise "Featured items of type #{item.content_type} are not yet supported"
    end

    FeaturedVideoItem.new(item, course)
  end

  class FeaturedVideoItem
    def initialize(item, course)
      @item = item
      @course = course
      @video = Video::Video.find item.content_id
    end

    def featured_image
      @video.thumbnail
    end

    extend Forwardable

    def_delegators :@item, :id, :title
    def_delegators :@course, :course_code
  end
end

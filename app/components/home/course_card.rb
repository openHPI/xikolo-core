# frozen_string_literal: true

module Home
  class CourseCard < ApplicationComponent
    def initialize(course, enrollment: nil)
      @course = course
      @enrollment = enrollment
    end

    private

    def upcoming?
      @course.published? && (@course.display_start_date || @course.start_date)&.future?
    end

    def completed?
      @enrollment&.completed?
    end

    def progress_percentage
      return 0 unless @enrollment.has_attribute?(:visits_percentage)

      @enrollment.visits_percentage || 0
    end

    def topics
      @course.classifiers('topic') if visible_clusters.include?('topic')
    end

    def level
      @course.classifiers('level').first if visible_clusters.include?('level')
    end

    def level_icon
      # Match the classifier's stable title, independently of its translation.
      title = @course.fixed_classifiers.find { it['cluster_id'] == 'level' }&.fetch('title')
      case title&.downcase
        when 'beginner' then 'cellular-signal-1'
        when 'intermediate' then 'cellular-signal-2'
        when 'expert' then 'cellular-signal-3'
        else 'cellular-signal-0'
      end
    end

    def visible_clusters
      @visible_clusters ||= Rails.cache.fetch(
        'web/course/clusters/visible',
        expires_in: 30.minutes,
        race_condition_ttl: 1.minute
      ) { ::CourseService::Cluster.visible.ids }
    end

    VISUAL_SIZES = {
      # Match grid-cols-1, md:grid-cols-2, lg:grid-cols-3 and xl:grid-cols-4, keeping
      # the image ratio at 16:9 within the 1370px content container.
      '(width < 48rem)': [768, 432],
      '(48rem <= width < 64rem)': [640, 360],
      '(64rem <= width < 80rem)': [448, 252],
      '(width >= 80rem)': [352, 198],
    }.freeze
    private_constant :VISUAL_SIZES

    Source = Struct.new(:media, :srcset)
    private_constant :Source

    def visuals
      default_opts = {resizing_type: 'fill', gravity: 'ce'}

      VISUAL_SIZES.map do |media, size|
        srcset = [
          Imagecrop.transform(fallback_visual, **default_opts, width: size[0], height: size[1]),
          "#{Imagecrop.transform(fallback_visual, **default_opts, width: size[0] * 2, height: size[1] * 2)} 2x",
        ]

        Source.new(media, srcset.join(', '))
      end
    end

    def fallback_visual
      @fallback_visual ||= course_visual || platform_visual_fallback
    end

    def course_visual
      Xikolo::S3.object(@course.visual.image_uri).public_url if @course.visual&.image_uri?
    end

    def platform_visual_fallback
      Xikolo.base_url.join(helpers.asset_path('defaults/course.png')).to_s
    end
  end
end

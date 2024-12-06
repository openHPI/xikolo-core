# frozen_string_literal: true

SitemapGenerator::Interpreter.send :require, 'sitemap_support'
SitemapGenerator::Interpreter.send :require, 'uri'

SitemapGenerator::Sitemap.default_host = Xikolo.base_url.to_s
SitemapGenerator::Sitemap.public_path = 'tmp/sitemaps'

SitemapGenerator::Sitemap.create do
  # Static pages linked in footer
  Xikolo.config.dig('footer', 'columns')&.pluck('links')&.each do |links|
    # Do not include referenced links for now (would be a String instead
    # of Hash). Additionally, do not include absolute URLs, i.e.
    # external links.
    links.select {|link| link.is_a?(Hash) && URI(link['href']).relative? }.each do |link|
      add link['href'],
        priority: 0.9,
        changefreq: 'weekly',
        alternates: SitemapSupport.language_alternates(link['href'])
    end
  end

  # Global news
  add '/news', priority: 1.0, changefreq: 'daily', alternates: SitemapSupport.language_alternates('/news')

  # Course overview
  add '/courses', priority: 1.0, changefreq: 'daily', alternates: SitemapSupport.language_alternates('/courses')

  # Course detail pages
  course_api = Xikolo.api(:course).value!
  all_courses = courses = course_api.rel(:courses).get(hidden: false, public: true).value!
  while courses.rel?(:next)
    courses = courses.rel(:next).get.value!
    all_courses += courses
  end
  course_visuals = Course::Visual.where(course_id: all_courses.pluck('id')).index_by(&:course_id)

  all_courses.each do |course|
    visual = course_visuals[course['id']]
    if visual&.video_stream.present?
      video = SitemapSupport.video_sitemap(
        visual.video_stream,
        course['title'],
        course['abstract']&.strip.to_s
      )
    end

    add(course_path(course['course_code']),
      priority: 0.8,
      changefreq: 'monthly',
      lastmod: course['updated_at'],
      alternates: SitemapSupport.language_alternates(course_path(course['course_code'])),
      video:)

    # add syllabus if open mode enabled
    if Xikolo.config.open_mode['enabled'] && course['show_syllabus']
      add course_overview_path(course['course_code']),
        priority: 0.8,
        changefreq: 'weekly',
        lastmod: course['updated_at'],
        alternates: SitemapSupport.language_alternates(course_overview_path(course['course_code']))
    end

    course_api.rel(:items).get(course_id: course['id'], open_mode: true).value!
      .select {|item| item['content_type'] == 'video' }
      .each do |item|
      stream = Video::Video.find(item['content_id']).pip_stream
      if stream.present?
        video = SitemapSupport.video_sitemap(
          stream,
          "#{course['title']} - #{item['title']}",
          SitemapSupport.video_description(item)
        )

        add(
          course_item_path(course_id: course['course_code'], id: UUID4(item['id']).to_param),
          priority: 0.8,
          changefreq: 'monthly',
          video:
        )
      end
    rescue ActiveRecord::NotFound
      next
    end
  end
end

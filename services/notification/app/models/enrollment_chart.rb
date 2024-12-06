# frozen_string_literal: true

# A class for generating the enrollment timeline diagrams used in statistic emails
#
class EnrollmentChart
  def initialize(course_statistics)
    @course_statistics = course_statistics
  end

  WIDTH = 800
  HEIGHT = 500

  def to_png
    g = SVG::Graph::Line.new(
      width: WIDTH,
      height: HEIGHT,
      fields: last_10_days_labels,
      show_graph_title: false,
      show_x_title: false,
      show_y_title: false,
      no_css: true
    )

    active_courses_with_enrollments do |stat|
      g.add_data(
        data: stat.enrollments_per_day,
        title: stat.course_code
      )
    end

    surface = Cairo::ImageSurface.new(Cairo::FORMAT_ARGB32, WIDTH, HEIGHT)
    Cairo::Context.new(surface).render_rsvg_handle(
      Rsvg::Handle.new(data: g.burn)
    )

    StringIO.new.tap do |io|
      surface.write_to_png(io)
    end.string
  end

  def empty?
    total_enrollment_count == 0
  end

  private

  def total_enrollment_count
    stats_for_active_courses.sum do |stat|
      stat.enrollments_per_day.size
    end
  end

  def active_courses_with_enrollments
    stats_for_active_courses.each do |stat|
      yield stat unless stat.enrollments_per_day.empty?
    end
  end

  def last_10_days_labels
    9.downto(0).map {|n| n.days.ago.strftime('%m-%d') }
  end

  def stats_for_active_courses
    @stats_for_active_courses ||= @course_statistics.flatten.select do |stat|
      stat.course_status == 'active'
    end
  end
end

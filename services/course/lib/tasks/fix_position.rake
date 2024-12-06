# frozen_string_literal: true

namespace :fix_position do
  desc <<-DOC.gsub(/\s+/, ' ')
  Fix all item position items to count from 1 upwards for each section (preserving order) and each course
  DOC
  task all_items: :environment do
    @rails_env = ENV.fetch('RAILS_ENV', nil)
    @dry = ENV.fetch('DRY', nil)

    Course.find_each do |course|
      reorder_items course.course_code
    end
  end

  desc <<-DOC.gsub(/\s+/, ' ')
  Fix all item position items to count from 1 upwards for each section (preserving order) of the course
  DOC
  task items_for_course: :environment do
    @rails_env = ENV.fetch('RAILS_ENV', nil)
    @dry = ENV.fetch('DRY', nil)
    @course_code = ENV.fetch('COURSE_CODE', nil)

    if @course_code
      reorder_items @course_code
    else
      $stdout.print "Missing one of the parameters [COURSE_CODE]\n"
    end
  end
  def reorder_items(course_code)
    $stdout.print "Reordering started for course #{course_code}...\n"
    $stdout.print "This is a DRY run...\n" if @dry

    begin
      changed = false
      Course.where(course_code:).first.sections.each do |section|
        new_pos = 1
        section.items.each do |item|
          if new_pos == item.position
            new_pos += 1
            next
          end
          old_pos = item.position
          item.position = new_pos
          new_pos += 1
          item.save unless @dry
          changed = true
          $stdout.print "#{section.title} - #{item.title}: " \
                        "#{old_pos} -> #{item.position}\n"
        end
      end

      $stdout.print "Nothing to reorder...\n" unless changed
      $stdout.print "\n"
      $stdout.flush
    rescue ActiveRecord::RecordNotFound
      $stdout.print "#{course_code} is not a valid course_code\n"
    end
  end
end

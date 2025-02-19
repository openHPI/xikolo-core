# frozen_string_literal: true

module Course
  class FeaturedCoursePreview < ViewComponent::Preview
    def default
      render ::Course::FeaturedCourse.new(course)
    end

    def with_enrollment
      render ::Course::FeaturedCourse.new(course, enrollment:)
    end

    def with_long_text
      render ::Course::FeaturedCourse.new(course_with_long_text)
    end

    private

    COURSE_ID = SecureRandom.uuid
    ENROLLMENT_ID = SecureRandom.uuid
    USER_ID = SecureRandom.uuid

    private_constant :ENROLLMENT_ID, :COURSE_ID, :USER_ID

    def course
      Catalog::Course.new({
        id: COURSE_ID,
        course_code: 'databases',
        title: 'Course Title',
        teacher_text: 'Prof. D. B. Expert',
        abstract: 'Equip yourself with the most impactful Design Thinking principles to unlock your innovation capacity
        in complex, highly constrained situations.',
        start_date: 2.weeks.ago,
        end_date: 3.weeks.from_now,
        lang: 'en',
        fixed_classifiers: [],
        roa_enabled: true,
      })
    end

    def course_with_long_text
      Catalog::Course.new({
        id: COURSE_ID,
        course_code: 'databases',
        title: 'Course Title',
        teacher_text: 'Prof. D. B. Expert',
        abstract: "
        Prow scuttle parrel provost Sail ho shrouds spirits boom mizzenmast yardarm.
        Pinnace holystone mizzenmast quartercrow's nest nipperkin grog yardarm hempen halter furl.
        Swab barque interloper chantey doubloon starboard grog black jack gangway rutters.
        Deadlights jack lad schooner scallywag dance the hempen jig carouser broadside cable strike colors.
        Bring a spring upon her cable holystone blow the man down spanker Shiver me timbers to go on account lookout.
        Belay yo-ho-ho keelhaul squiffy black spot yardarm spyglass sheet transom heave to.
        Trysail Sail ho Corsair red ensign hulk smartly boom jib rum gangway.
        Case shot Shiver me timbers gangplank crack Jennys tea cup ballast Blimey lee snow crow's nest rutters.
        Fluke jib scourge of the seven seas boatswain schooner gaff booty Jack Tar transom spirits.
        ",
        start_date: 2.weeks.ago,
        end_date: 3.weeks.from_now,
        lang: 'en',
        fixed_classifiers: [],
        roa_enabled: true,
      })
    end

    def enrollment
      ::Course::Enrollment.new({
        id: ENROLLMENT_ID,
        course_id: COURSE_ID,
        user_id: USER_ID,
      })
    end
  end
end

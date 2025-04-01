# frozen_string_literal: true

# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

##### Channels #####

channel1 = Channel.create!(
  id: '00000001-3300-5555-9999-000000000001',
  code: 'social',
  name: 'Get Social!',
  public: true,
  archived: false,
  position: 1,
  info_link: {
    'href' => {'en' => 'https://www.example.com/faq'},
    'label' => {'en' => 'Our FAQ'},
  },
  description: {
    'en' => <<~TEXT.strip,
      Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy
      eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam
      voluptua. At vero eos et accusam et justo duo dolores et ea rebum. Stet
      clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit
      amet. Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam
      nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat,
      sed diam voluptua. At vero eos et accusam et justo duo dolores et ea
      rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum
      dolor sit amet. Lorem ipsum dolor sit amet, consetetur sadipscing elitr,
      sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam
      erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et
      ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem
      ipsum dolor sit amet.

      Duis autem vel eum iriure dolor in hendrerit in vulputate velit esse
      molestie consequat, vel illum dolore eu feugiat nulla facilisis at vero
      eros et accumsan et iusto odio dignissim qui blandit praesent luptatum
      zzril delenit augue duis dolore te feugait nulla facilisi.
    TEXT
  }
)

channel2 = Channel.create!(
  id: '00000001-3300-5555-9999-000000000002',
  code: 'outbreak',
  name: 'Disease Outbreaks of the day',
  public: true,
  archived: false,
  position: 2
)

channel3 = Channel.create!(
  id: '00000001-3300-5555-9999-000000000003',
  code: 'goarn',
  name: 'GOARN',
  public: true,
  archived: false,
  position: 3
)

##### Categories #####

topic = Cluster.create! id: 'topic', translations: {'en' => 'Topics', 'de' => 'Themen'}
topic.classifiers.create! title: 'Databases', translations: {'en' => 'Databases', 'de' => 'Datenbanken'}, position: 1
topic.classifiers.create! title: 'Fundamentals', translations: {'en' => 'Fundamentals', 'de' => 'Grundlagen'}, position: 2
topic.classifiers.create! title: 'Internet', translations: {'en' => 'Internet', 'de' => 'Internet'}, position: 3
topic.classifiers.create! title: 'Programming', translations: {'en' => 'Programming', 'de' => 'Programmierung'}, position: 4

level = Cluster.create! id: 'level', translations: {'en' => 'Level', 'de' => 'Niveau'}
level.classifiers.create! title: 'Junior', translations: {'en' => 'Junior', 'de' => 'Junior'}, position: 4
level.classifiers.create! title: 'Beginner', translations: {'en' => 'Beginner', 'de' => 'Anfänger'}, position: 1
level.classifiers.create! title: 'Advanced', translations: {'en' => 'Advanced', 'de' => 'Fortgeschrittene'}, position: 2
level.classifiers.create! title: 'Expert', translations: {'en' => 'Expert', 'de' => 'Experten'}, position: 3

reporting = Cluster.create! id: 'reporting', translations: {'en' => 'Reporting', 'de' => 'Reporting'}, visible: false
reporting.classifiers.create! title: 'dashboard', translations: {'en' => 'Dashboard', 'de' => 'Dashboard'}, position: 1

##### Courses #####

context_uuid = '81e01000-%d-4444-a%03d-0000000%05d'

teacher = Teacher.create!(
  name: 'Grandmaster Yoda',
  description: {en: 'He is a teacher', de: 'Er ist ein Lehrer'}
)

courses = []
courses << Course::Create.call(
  id: '00000001-3300-4444-9999-000000000001',
  title: 'Cloud und Virtualisierung',
  course_code: 'cloud2013',
  context_id: format(context_uuid, 3100, 2, 1),
  description: <<~DESCRIPTION.squish,
    Eine breit akzeptierte Definition des Begriffs Cloud Computing gibt es bis
    heute nicht. Allerdings können die grundlegenden Eigenschaften wie folgt
    zusammengefasst werden: Cloud Computing nutzt Virtualisierung und das Internet
    zur dynamischen Bereitstellung von IT-Ressourcen. Dabei kann es sich um
    IT-Infrastruktur, Plattformen oder Anwendungen aller Art handeln. Cloud
    Computing bezeichnet also sowohl Anwendungen, welche als Dienste über das
    Internet angeboten werden, als auch die Hard- und Software, die in
    Rechenzentren zu deren Bereitstellung benötigt werden. Die Abrechnung erfolgt
    dabei stets nach Verbrauch.
  DESCRIPTION
  abstract: <<~ABSTRACT.squish,
    In dem Kurs Cloud und Visualisierung lernen Sie so einiges. Das Web –
    eigentlich nichts anderes als ein einfacher Informationsdienst im Internet
    – hat eine ganz neue digitale Welt entstehen lassen, die eng verwoben mit
    unserer realen Welt früher Unvorstellbares möglich macht: sekundenschnelle
    Kommunikation über Kontinente, Filme auf dem Smartphone anschauen, mit
    Partnern in entfernten Ländern spielen oder Fotos anschauen oder vom Sofa
    aus einkaufen und Bankgeschäfte tätigen…
  ABSTRACT
  start_date: Date.yesterday - 60,
  end_date: Date.yesterday,
  status: 'archive',
  lang: 'de',
  classifiers: {topic: %w[Internet], level: %w[Advanced]},
  channel: channel1,
  teacher_ids: [teacher.id]
).tap do |c|
  c.offers.create!
end

courses << Course::Create.call(
  id: '00000001-3300-4444-9999-000000000002',
  title: 'Geovisualisierung',
  course_code: 'geo2013',
  context_id: format(context_uuid, 3100, 2, 2),
  description: <<~DESCRIPTION.squish,
    Die Vorlesung vermittelt Konzepte und Techniken der Visualisierung
    raumbezogener Daten. Im Mittelpunkt stehen dabei die Modellierung,
    Prozessierung, Visualisierung und Verteilung von raumbezogenen Informationen
    mit Hilfe virtueller 3D-Stadtmodelle und 3D-Landschaftsmodelle.
  DESCRIPTION
  abstract: <<~ABSTRACT.squish,
    Die Vorlesung vermittelt Konzepte und Techniken der Visualisierung
    raumbezogener Daten.
  ABSTRACT
  start_date: Date.yesterday - 60,
  end_date: Date.tomorrow,
  status: 'active',
  lang: 'de',
  classifiers: {topic: %w[Programming], level: %w[Advanced]},
  channel: channel1,
  target_groups: [
    'Humans', 'People who like Bananas', 'Bananas'
  ],
  learning_goals: [
    'Build an autonomously operating Submarine', 'Ride a Dinosaur', 'Find inner Peace'
  ]
)

courses << Course::Create.call(
  id: '00000001-3300-4444-9999-000000000003',
  title: 'Trends and Concepts in the Software Industry',
  course_code: 'trend2013',
  context_id: format(context_uuid, 3100, 2, 3),
  description: <<~DESCRIPTION.squish,
    The focus of this lecture is on enterprise applications, especially with
    regards to in-memory databases and a programming model for enterprise
    applications. The lecture will largely be based on the new In-Memory Data
    Management book by Prof. Hasso Plattner, which will be given for free to all
    enrolled students at V-2.11 (Andrea Lange). Students can pick up their copy
    once the enrollment date (Belegungsfrist) has passed. The latest enrollment
    date for this lecture is April 30th, 2013.
  DESCRIPTION
  abstract: <<~ABSTRACT.squish,
    This is another short abstract about Trends and Concepts in the Software
    Industry
  ABSTRACT
  start_date: Date.yesterday - 30,
  end_date: Date.tomorrow + 30,
  status: 'active',
  lang: 'en',
  classifiers: {topic: %w[Fundamentals], level: %w[Beginner]},
  channel: channel2
)

courses << Course::Create.call(
  id: '00000001-3300-4444-9999-000000000004',
  title: 'Data Profiling and Data Cleansing',
  course_code: 'data-cleansing2013',
  context_id: format(context_uuid, 3100, 2, 4),
  description: <<~DESCRIPTION.squish,
    According to Wikipedia, data profiling is the process of examining the
    data available in an existing data source [...] and collecting statistics
    and information about that data. It encompasses a vast array of methods to
    examine data sets and produce metadata. Among the simpler results are
    statistics, such as the number of null values and distinct values in a
    column, its data type, or the most frequent patterns of its data values.
    Metadata that are more difficult to compute usually involve multiple
    columns, such as inclusion dependencies or functional dependencies between
    columns. More advanced techniques detect approximate properties or
    conditional properties of the data set at hand. The first part of the
    lecture examines efficient detection methods for these properties.
  DESCRIPTION
  abstract: <<~ABSTRACT.squish,
    This is another short abstract about Data Profiling and Data Cleansing
  ABSTRACT
  start_date: Time.zone.today,
  end_date: Date.tomorrow + 60,
  status: 'preparation',
  lang: 'en',
  classifiers: {topic: %w[Databases], level: %w[Expert]},
  channel: channel3
)

courses << Course::Create.call(
  id: '00000001-3300-4444-9999-000000000005',
  title: 'Software Profiling',
  course_code: 'sw-profiling2013',
  context_id: format(context_uuid, 3100, 2, 5),
  description: <<~DESCRIPTION.squish,
    Software profiling is an established technique for the dynamic analysis of
    running programs. It supports the software developer or product maintainer
    in understanding code execution paths, resource consumption behavior and
    communication patterns. Software profiling typically does not demand
    access to the source code of the application at measurement time, which
    makes it perfectly usable in production environments and distributed
    (cloud) systems.
  DESCRIPTION
  abstract: <<~ABSTRACT.squish,
    This course addresses all people intered in Software Profiling.
  ABSTRACT
  start_date: Date.tomorrow,
  end_date: Date.tomorrow + 62,
  status: 'preparation',
  lang: 'en',
  classifiers: {topic: %w[Programming], level: %w[Beginner]},
  channel: channel2
)

courses << Course::Create.call(
  id: '00000001-3300-4444-9999-000000000006',
  title: 'Software Profiling Future',
  course_code: 'sw-profiling2015',
  context_id: format(context_uuid, 3100, 2, 6),
  description: <<~DESCRIPTION.squish,
    Software profiling is an established technique for the dynamic analysis of
    running programs. It supports the software developer or product maintainer
    in understanding code execution paths, resource consumption behavior and
    communication patterns. Software profiling typically does not demand
    access to the source code of the application at measurement time, which
    makes it perfectly usable in production environments and distributed
    (cloud) systems.
  DESCRIPTION
  abstract: <<~ABSTRACT.squish,
    This course addresses all people interested in Software Profiling.
  ABSTRACT
  start_date: Date.tomorrow + 600,
  end_date: Date.tomorrow + 662,
  status: 'active',
  lang: 'en',
  classifiers: {topic: %w[Programming], level: %w[Beginner]},
  channel: channel3
)

courses << Course::Create.call(
  id: '00000001-3300-4444-9999-000000000007',
  title: 'Hidden Course',
  course_code: 'hidden',
  context_id: format(context_uuid, 3100, 2, 7),
  description: <<~DESCRIPTION.squish,
    Software profiling is an established technique for the dynamic analysis of
    running programs. It supports the software developer or product maintainer
    in understanding code execution paths, resource consumption behavior and
    communication patterns. Software profiling typically does not demand
    access to the source code of the application at measurement time, which
    makes it perfectly usable in production environments and distributed
    (cloud) systems.
  DESCRIPTION
  abstract: <<~ABSTRACT.squish,
    This course is hidden.
  ABSTRACT
  start_date: Date.tomorrow + 600,
  end_date: Date.tomorrow + 662,
  status: 'active',
  hidden: true,
  lang: 'en',
  classifiers: {topic: %w[Fundamentals], level: %w[Junior]},
  channel: channel3
)

##### Enrollments #####

# ensure at least 200 user accounts has been seeded too

# there was some mistake with matching enrollments to users (the users specified here did not exist)
# if this fix causes any trouble, please fix the seeds on your side
3.upto(199) do |i|
  Enrollment::Create.call(
    format('00000001-3100-4444-9999-0000000%05d', i + 100),
    courses[0]
  )
end

Enrollment::Create.call(
  '00000001-3100-4444-9999-000000000001',
  courses[0]
)

Enrollment::Create.call(
  '00000001-3100-4444-9999-000000000002',
  courses[0]
)

Enrollment::Create.call(
  '00000001-3100-4444-9999-000000000002',
  courses[1]
)

Enrollment::Create.call(
  '00000001-3100-4444-9999-000000000003',
  courses[0]
)

Enrollment::Create.call(
  '00000001-3100-4444-9999-000000000003',
  courses[1]
)

Enrollment::Create.call(
  '00000001-3100-4444-9999-000000000003',
  courses[2]
)

##### Sections #####
## IMPORTANT!: Ids of sections and video items are referenced in pinboard service.
## If you add or change a section or video add tag with new id as name in pinboard seed
## If you don't, tests will fail.

introduction_section = Section.create!(
  id: '00000002-3100-4444-9999-000000000001',
  title: 'Introduction',
  description: 'A first insight in the topic.',
  start_date: 1.day.ago,
  end_date: 1.day.from_now,
  published: true,
  course: courses[0],
  position: 1
)

definitions_section = Section.create!(
  id: '00000002-3100-4444-9999-000000000002',
  title: 'Definitions',
  description: 'Explanation of important terms.',
  start_date: 1.day.ago,
  end_date: 1.day.from_now,
  published: true,
  course: courses[0],
  position: 2
)

Section.create!(
  id: '00000002-3100-4444-9999-000000000003',
  title: 'Published but in future',
  description: 'Explanation of important terms.',
  start_date: 1.day.from_now,
  end_date: 10.days.from_now,
  published: true,
  course: courses[0],
  position: 3
)

Section.create!(
  id: '00000002-3100-4444-9999-000000000004',
  title: 'Published and expired',
  description: 'Explanation of important terms.',
  start_date: 10.days.ago,
  end_date: 1.day.ago,
  published: true,
  course: courses[0],
  position: 4
)

Section.create!(
  id: '00000002-3100-4444-9999-000000000005',
  title: 'Not Published and in future',
  description: 'Explanation of important terms.',
  start_date: 1.day.from_now,
  end_date: 10.days.from_now,
  published: false,
  course: courses[0],
  position: 5
)

Section.create!(
  id: '00000002-3100-4444-9999-000000000006',
  title: 'Not Published',
  description: 'Explanation of important terms.',
  start_date: 1.day.ago,
  end_date: 10.days.from_now,
  published: false,
  course: courses[0],
  position: 6
)

final_exam_section = Section.create!(
  id: '00000002-3100-4444-9999-000000000009',
  title: 'Final Exam',
  description: 'The final exam of this course.',
  start_date: 1.day.ago,
  end_date: 10.days.from_now,
  published: true,
  course: courses[0],
  position: 7
)

introduction2_section = Section.create!(
  id: '00000002-3100-4444-9999-000000000007',
  title: 'Introduction',
  description: 'A first insight in the topic.',
  start_date: 2.days.ago,
  end_date: 7.days.from_now,
  published: true,
  course: courses[1],
  position: 1
)

Section.create!(
  id: '00000002-3100-4444-9999-000000000008',
  title: 'Definitions',
  description: 'Explanation of important terms.',
  start_date: 2.days.from_now,
  end_date: 5.days.from_now,
  published: true,
  course: courses[1],
  position: 2
)

specialization_section = Section.create!(
  id: '00000002-3100-4444-9999-000000000012',
  title: 'Specializations',
  description: 'Deep dive into different specialized tocpics',
  start_date: 2.days.ago,
  end_date: 14.days.from_now,
  published: true,
  course: courses[1],
  alternative_state: 'parent',
  position: 3
)

spec_section_alt1 = Section.create!(
  id: '00000002-3100-4444-9999-000000000010',
  title: 'Urban Planning',
  description: 'Both planners and the general public can use geovisualization to explore real-world environments and model ‘what if’ scenarios based on spatio-temporal data.',
  start_date: 2.days.ago,
  end_date: 14.days.from_now,
  published: true,
  course: courses[1],
  alternative_state: 'child',
  parent_id: specialization_section.id,
  position: 3
)

spec_section_alt2 = Section.create!(
  id: '00000002-3100-4444-9999-000000000011',
  title: 'Environmental Studies',
  description: 'Geovisualization tools provide multiple stakeholders with the ability to make balanced environmental decisions by taking into account the “the complex interacting factors that should be taken into account when studying environmental changes”',
  start_date: 2.days.ago,
  end_date: 14.days.from_now,
  published: true,
  course: courses[1],
  alternative_state: 'child',
  parent_id: specialization_section.id,
  position: 3
)

##### Items #####
richtext = Richtext.create!(
  course_id: introduction_section.course_id,
  text: <<~TEXT
    An h1 header
    ============

    Paragraphs are separated by a blank line.

    2nd paragraph. *Italic*, **bold**, `monospace`. Itemized lists
    look like:

      * this one
      * that one
      * the other one

    Note that --- not considering the asterisk --- the actual text
    content starts at 4-columns in.

    > Block quotes are
    > written like so.
    >
    > They can span multiple paragraphs,
    > if you like.

    Use 3 dashes for an em-dash. Use 2 dashes for ranges (ex. it's all in
    chapters 12--14). Three dots ... will be converted to an ellipsis.



    An h2 header
    ------------

    Here's a numbered list:

                                                                                                                  1. first item
    2. second item
    3. third item

    Note again how the actual text starts at 4 columns in (4 characters
    from the left side). Here's a code sample:

        # Let me re-iterate ...
        for i in 1 .. 10 { do-something(i) }

    As you probably guessed, indented 4 spaces. By the way, instead of
    indenting the block, you can use delimited blocks, if you like:

    ~~~
    define foobar() {
        print 'Welcome to flavor country!';
    }
    ~~~

    (which makes copying & pasting easier). You can optionally mark the
    delimited block for Pandoc to syntax highlight it:

    ~~~python
    import time
    # Quick, count to ten!
    for i in range(10):
        # (but not *too* quick)
        time.sleep(0.5)
        print i
    ~~~



    ### An h3 header ###

    Now a nested list:

    1. First, get these ingredients:

          * carrots
          * celery
          * lentils

    2. Boil some water.

    3. Dump everything in the pot and follow
        this algorithm:

            find wooden spoon
            uncover pot
            stir
            cover pot
            balance wooden spoon precariously on pot handle
            wait 10 minutes
            goto first step (or shut off burner when done)

        Do not bump wooden spoon or it will fall.

    Notice again how text always lines up on 4-space indents (including
    that last line which continues item 3 above). Here's a link to [a
    website](http://foo.bar). Here's a link to a [local
    doc](local-doc.html). Here's a footnote [^1].

        [^1]: Footnote text goes here.

                                    Tables can look like this:

                                                              size  material      color
    ----  ------------  ------------
    9     leather       brown
    10    hemp canvas   natural
    11    glass         transparent

    Table: Shoes, their sizes, and what they're made of

    (The above is the caption for the table.) Here's a definition list:

                                                                                                              apples
    : Good for making applesauce.
        oranges
            : Citrus!
            tomatoes
            : There's no 'e' in tomatoe.

    Again, text is indented 4 spaces. (Alternately, put blank lines in
    between each of the above definition list lines to spread things
    out more.)

    Inline math equations go in like so: $\omega = d\phi / dt$. Display
    math should get its own line and be put in in double-dollarsigns:

    $$I = \int \rho R^{2} dV$$

    Done."
  TEXT
)

Item.create!(
  title: 'Markdown Example not shown in Nav',
  start_date: 10.days.ago,
  end_date: 14.days.from_now,
  content_type: 'rich_text',
  content_id: richtext.id,
  section: introduction_section,
  show_in_nav: false,
  id: '00000003-3100-4444-9999-000000000001'
)

Item.create!(
  title: 'Introduction Speech',
  start_date: 2.days.ago,
  end_date: 5.days.from_now,
  content_type: 'video',
  content_id: '00000001-3600-4444-9999-000000000001',
  section: introduction_section,
  id: '00000003-3100-4444-9999-000000000002'
)

Item.create!(
  title: 'Welcome',
  start_date: 2.days.ago,
  end_date: 5.days.from_now,
  content_type: 'video',
  content_id: '00000001-3600-4444-9999-000000000004',
  section: introduction_section,
  show_in_nav: true,
  id: '00000003-3100-4444-9999-000000000003'
)

richtext = Richtext.create!(
  course_id: introduction_section.course_id,
  text: <<~TEXT
    An h1 header
    ============

    Paragraphs are separated by a blank line.

    2nd paragraph. *Italic*, **bold**, `monospace`. Itemized lists
    look like:

      * this one
      * that one
      * the other one

    Note that --- not considering the asterisk --- the actual text
    content starts at 4-columns in.

    > Block quotes are
    > written like so.
    >
    > They can span multiple paragraphs,
    > if you like.

    Use 3 dashes for an em-dash. Use 2 dashes for ranges (ex. it's all in
    chapters 12--14). Three dots ... will be converted to an ellipsis.



    An h2 header
    ------------

    Here's a numbered list:

                                                                                                                  1. first item
    2. second item
    3. third item

    Note again how the actual text starts at 4 columns in (4 characters
    from the left side). Here's a code sample:

        # Let me re-iterate ...
        for i in 1 .. 10 { do-something(i) }

    As you probably guessed, indented 4 spaces. By the way, instead of
    indenting the block, you can use delimited blocks, if you like:

    ~~~
    define foobar() {
        print 'Welcome to flavor country!';
    }
    ~~~

    (which makes copying & pasting easier). You can optionally mark the
    delimited block for Pandoc to syntax highlight it:

    ~~~python
    import time
    # Quick, count to ten!
    for i in range(10):
        # (but not *too* quick)
        time.sleep(0.5)
        print i
    ~~~



    ### An h3 header ###

    Now a nested list:

    1. First, get these ingredients:

          * carrots
          * celery
          * lentils

    2. Boil some water.

    3. Dump everything in the pot and follow
        this algorithm:

            find wooden spoon
            uncover pot
            stir
            cover pot
            balance wooden spoon precariously on pot handle
            wait 10 minutes
            goto first step (or shut off burner when done)

        Do not bump wooden spoon or it will fall.

    Notice again how text always lines up on 4-space indents (including
    that last line which continues item 3 above). Here's a link to [a
    website](http://foo.bar). Here's a link to a [local
    doc](local-doc.html). Here's a footnote [^1].

        [^1]: Footnote text goes here.

                                    Tables can look like this:

                                                              size  material      color
    ----  ------------  ------------
    9     leather       brown
    10    hemp canvas   natural
    11    glass         transparent

    Table: Shoes, their sizes, and what they're made of

    (The above is the caption for the table.) Here's a definition list:

                                                                                                              apples
    : Good for making applesauce.
        oranges
            : Citrus!
            tomatoes
            : There's no 'e' in tomatoe.

    Again, text is indented 4 spaces. (Alternately, put blank lines in
    between each of the above definition list lines to spread things
    out more.)

    Inline math equations go in like so: $\omega = d\phi / dt$. Display
    math should get its own line and be put in in double-dollarsigns:

    $$I = \int \rho R^{2} dV$$

    Done."
  TEXT
)

Item.create!(
  title: 'Markdown Example',
  start_date: 2.days.ago,
  end_date: 5.days.from_now,
  content_type: 'rich_text',
  content_id: richtext.id,
  section: introduction_section,
  show_in_nav: true,
  id: '00000003-3100-4444-9999-000000000004'
)

Item.create!(
  title: 'Welcome Quiz',
  start_date: 2.days.ago,
  end_date: 5.days.from_now,
  content_type: 'quiz',
  exercise_type: 'selftest',
  content_id: '00000001-3800-4444-9999-000000000001',
  section: introduction_section,
  show_in_nav: true,
  id: '00000003-3100-4444-9999-000000000005'
)

Item.create!(
  title: 'Quiz with all question types',
  start_date: 2.days.ago,
  end_date: 5.days.from_now,
  content_type: 'quiz',
  exercise_type: 'selftest',
  content_id: '00000001-3800-4444-9999-000000000006',
  section: introduction_section,
  show_in_nav: true,
  id: '00000003-3100-4444-9999-000000000027'
)

richtext = Richtext.create!(
  course_id: introduction_section.course_id,
  text: <<~TEXT
    An h1 header
    ============

    Paragraphs are separated by a blank line.

    2nd paragraph. *Italic*, **bold**, `monospace`. Itemized lists
    look like:

      * this one
      * that one
      * the other one

    Note that --- not considering the asterisk --- the actual text
    content starts at 4-columns in.

    > Block quotes are
    > written like so.
    >
    > They can span multiple paragraphs,
    > if you like.

    Use 3 dashes for an em-dash. Use 2 dashes for ranges (ex. it's all in
    chapters 12--14). Three dots ... will be converted to an ellipsis.



    An h2 header
    ------------

    Here's a numbered list:

                                                                                                                  1. first item
    2. second item
    3. third item

    Note again how the actual text starts at 4 columns in (4 characters
    from the left side). Here's a code sample:

        # Let me re-iterate ...
        for i in 1 .. 10 { do-something(i) }

    As you probably guessed, indented 4 spaces. By the way, instead of
    indenting the block, you can use delimited blocks, if you like:

    ~~~
    define foobar() {
        print 'Welcome to flavor country!';
    }
    ~~~

    (which makes copying & pasting easier). You can optionally mark the
    delimited block for Pandoc to syntax highlight it:

    ~~~python
    import time
    # Quick, count to ten!
    for i in range(10):
        # (but not *too* quick)
        time.sleep(0.5)
        print i
    ~~~



    ### An h3 header ###

    Now a nested list:

    1. First, get these ingredients:

          * carrots
          * celery
          * lentils

    2. Boil some water.

    3. Dump everything in the pot and follow
        this algorithm:

            find wooden spoon
            uncover pot
            stir
            cover pot
            balance wooden spoon precariously on pot handle
            wait 10 minutes
            goto first step (or shut off burner when done)

        Do not bump wooden spoon or it will fall.

    Notice again how text always lines up on 4-space indents (including
    that last line which continues item 3 above). Here's a link to [a
    website](http://foo.bar). Here's a link to a [local
    doc](local-doc.html). Here's a footnote [^1].

        [^1]: Footnote text goes here.

                                    Tables can look like this:

                                                              size  material      color
    ----  ------------  ------------
    9     leather       brown
    10    hemp canvas   natural
    11    glass         transparent

    Table: Shoes, their sizes, and what they're made of

    (The above is the caption for the table.) Here's a definition list:

                                                                                                              apples
    : Good for making applesauce.
        oranges
            : Citrus!
            tomatoes
            : There's no 'e' in tomatoe.

    Again, text is indented 4 spaces. (Alternately, put blank lines in
    between each of the above definition list lines to spread things
    out more.)

    Inline math equations go in like so: $\omega = d\phi / dt$. Display
    math should get its own line and be put in in double-dollarsigns:

    $$I = \int \rho R^{2} dV$$

    Done.
  TEXT
)

Item.create!(
  title: 'Markdown Example in future',
  start_date: 2.days.from_now,
  end_date: 5.days.from_now,
  content_type: 'rich_text',
  content_id: richtext.id,
  section: introduction_section,
  show_in_nav: true,
  id: '00000003-3100-4444-9999-000000000006'
)

Item.create!(
  title: 'Introduction in Definitions',
  start_date: 2.days.from_now,
  end_date: 5.days.from_now,
  content_type: 'video',
  content_id: '00000001-3600-4444-9999-000000000001',
  section: definitions_section,
  id: '00000003-3100-4444-9999-000000000007'
)

Item.create!(
  title: 'Definitions Quiz',
  start_date: 2.days.from_now,
  end_date: 5.days.from_now,
  content_type: 'quiz',
  exercise_type: 'selftest',
  content_id: '00000001-3800-4444-9999-000000000002',
  section: definitions_section,
  show_in_nav: true,
  id: '00000003-3100-4444-9999-000000000008'
)

Item.create!(
  title: 'Homework',
  start_date: 2.days.ago,
  content_type: 'quiz',
  exercise_type: 'main',
  content_id: '00000001-3800-4444-9999-000000000004',
  section: definitions_section,
  show_in_nav: true,
  id: '00000003-3100-4444-9999-000000000015'
)

Item.create!(
  title: 'Introduction Speech for Geo',
  start_date: 2.days.ago,
  end_date: 7.days.from_now,
  content_type: 'video',
  content_id: '00000001-3600-4444-9999-000000000003',
  section: introduction2_section,
  open_mode: true,
  show_in_nav: true,
  id: '00000003-3100-4444-9999-000000000009'
)

Item.create!(
  title: 'Welcome to Geo',
  start_date: 2.days.ago,
  end_date: 7.days.from_now,
  content_type: 'video',
  content_id: '00000001-3600-4444-9999-000000000004',
  section: introduction2_section,
  show_in_nav: true,
  id: '00000003-3100-4444-9999-000000000010'
)

Item.create!(
  title: 'Yet another dual stream video',
  start_date: 2.days.ago,
  end_date: 5.days.from_now,
  content_type: 'video',
  content_id: '00000001-3600-4444-9999-000000000005',
  section: definitions_section,
  show_in_nav: true,
  id: '00000003-3100-4444-9999-000000000011'
)

Item.create!(
  title: 'Kaltura video',
  start_date: 2.days.ago,
  end_date: 5.days.from_now,
  content_type: 'video',
  content_id: '00000001-3600-4444-9999-000000000006',
  section: introduction_section,
  show_in_nav: true,
  id: '00000003-3100-4444-9999-000000000012'
)

Item.create!(
  title: 'Welcome Survey',
  start_date: 2.days.ago,
  end_date: 5.days.from_now,
  content_type: 'quiz',
  exercise_type: 'survey',
  content_id: '00000001-3800-4444-9999-000000000003',
  section: introduction_section,
  show_in_nav: true,
  id: '00000003-3100-4444-9999-000000000014',
  position: 1
)

Item.create!(
  title: 'Final Exam',
  start_date: 2.days.ago,
  end_date: 5.days.from_now,
  content_type: 'quiz',
  exercise_type: 'main',
  content_id: '00000001-3800-4444-9999-000000000005',
  section: final_exam_section,
  show_in_nav: true,
  id: '00000003-3100-4444-9999-000000000016',
  position: 1
)

1.upto(30) do |i|
  richtext = Richtext.create!(
    course_id: introduction_section.course_id,
    text: <<~TEXT
      An h1 header
      ============

      Paragraphs are separated by a blank line.

      2nd paragraph. *Italic*, **bold**, `monospace`. Itemized lists
      look like:

        * this one
        * that one
        * the other one

      Note that --- not considering the asterisk --- the actual text
      content starts at 4-columns in.

      > Block quotes are
      > written like so.
      >
      > They can span multiple paragraphs,
      > if you like.

      Use 3 dashes for an em-dash. Use 2 dashes for ranges (ex. it's all in
      chapters 12--14). Three dots ... will be converted to an ellipsis.



      An h2 header
      ------------

      Here's a numbered list:

                                                                                                                    1. first item
      2. second item
      3. third item

      Note again how the actual text starts at 4 columns in (4 characters
      from the left side). Here's a code sample:

          # Let me re-iterate ...
          for i in 1 .. 10 { do-something(i) }

      As you probably guessed, indented 4 spaces. By the way, instead of
      indenting the block, you can use delimited blocks, if you like:

      ~~~
      define foobar() {
          print 'Welcome to flavor country!';
      }
      ~~~

      (which makes copying & pasting easier). You can optionally mark the
      delimited block for Pandoc to syntax highlight it:

      ~~~python
      import time
      # Quick, count to ten!
      for i in range(10):
          # (but not *too* quick)
          time.sleep(0.5)
          print i
      ~~~



      ### An h3 header ###

      Now a nested list:

      1. First, get these ingredients:

            * carrots
            * celery
            * lentils

      2. Boil some water.

      3. Dump everything in the pot and follow
          this algorithm:

              find wooden spoon
              uncover pot
              stir
              cover pot
              balance wooden spoon precariously on pot handle
              wait 10 minutes
              goto first step (or shut off burner when done)

          Do not bump wooden spoon or it will fall.

      Notice again how text always lines up on 4-space indents (including
      that last line which continues item 3 above). Here's a link to [a
      website](http://foo.bar). Here's a link to a [local
      doc](local-doc.html). Here's a footnote [^1].

          [^1]: Footnote text goes here.

                                      Tables can look like this:

                                                                size  material      color
      ----  ------------  ------------
      9     leather       brown
      10    hemp canvas   natural
      11    glass         transparent

      Table: Shoes, their sizes, and what they're made of

      (The above is the caption for the table.) Here's a definition list:

                                                                                                                apples
      : Good for making applesauce.
          oranges
              : Citrus!
              tomatoes
              : There's no 'e' in tomatoe.

      Again, text is indented 4 spaces. (Alternately, put blank lines in
      between each of the above definition list lines to spread things
      out more.)

      Inline math equations go in like so: $\omega = d\phi / dt$. Display
      math should get its own line and be put in in double-dollarsigns:

      $$I = \int \rho R^{2} dV$$

      Done.
    TEXT
  )

  Item.create!(
    title: format('Markdown Test %05d', i),
    content_type: 'rich_text',
    content_id: richtext.id,
    section: introduction_section,
    show_in_nav: true
  )
end

Item.create!(
  title: 'Welcome to Urban Planning',
  start_date: 2.days.ago,
  end_date: 5.days.from_now,
  content_type: 'video',
  content_id: '00000001-3600-4444-9999-000000000004',
  section: spec_section_alt1,
  show_in_nav: true,
  id: '00000003-3100-4444-9999-000000000017'
)

Item.create!(
  title: 'Welcome to Environmental Studies',
  start_date: 2.days.ago,
  end_date: 5.days.from_now,
  content_type: 'video',
  content_id: '00000001-3600-4444-9999-000000000004',
  section: spec_section_alt2,
  show_in_nav: true,
  id: '00000003-3100-4444-9999-000000000018'
)

item1 = Item.create!(
  title: 'Urban Planning Quiz',
  start_date: 2.days.ago,
  end_date: 5.days.from_now,
  content_type: 'quiz',
  exercise_type: 'main',
  content_id: '00000001-3800-4444-9999-000000000001',
  section: spec_section_alt1,
  show_in_nav: true,
  id: '00000003-3100-4444-9999-000000000019',
  max_dpoints: 60
)

item2 = Item.create!(
  title: 'Environmental Studies Quiz',
  start_date: 2.days.ago,
  end_date: 5.days.from_now,
  content_type: 'quiz',
  exercise_type: 'main',
  content_id: '00000001-3800-4444-9999-000000000004',
  section: spec_section_alt2,
  show_in_nav: true,
  id: '00000003-3100-4444-9999-000000000020',
  max_dpoints: 30
)

##### Documents and Localizations  #####

# #1##
document1 = Document.create!(
  title: 'Fantastic Beasts and where to find them',
  description: 'A nice book by J.K.Rowling',
  tags: %w[fantasy beasts wizard witchcraft wizadry Rowling],
  id: '00000001-3800-5555-9999-000000000001',
  courses: [courses.fourth, courses.second],
  items: [item1, item2]
)

DocumentLocalization.create!(
  title: 'Fantastische Tierwesen und wo sie zu finden sind',
  description: 'J.K.Rowling ist die Beste',
  id: '00000001-3800-5555-9997-000000000001',
  document: document1,
  file_id: '00000001-4000-4444-9999-000000000008',
  language: 'de',
  revision: '1'
)

DocumentLocalization.create!(
  title: 'Les Animaux fantastiques (Harry Potter)',
  description: 'livre de J.K.R.',
  id: '00000001-3800-5555-9997-000000000002',
  document: document1,
  file_id: '00000001-4000-4444-9999-000000000008',
  language: 'fr',
  revision: '1'
)

DocumentLocalization.create!(
  title: 'Fantastic Beasts and where to find them',
  description: 'A somewhat interesting book by J.K.R.',
  id: '00000001-3800-5555-9997-000000000003',
  document: document1,
  file_id: '00000001-4000-4444-9999-000000000008',
  language: 'en',
  revision: '1'
)

# #2##
document2 = Document.create!(
  title: 'Quidditch through the Ages',
  description: 'A nice book by J.K.Rowling',
  tags: %w[fantasy sports quidditch witchcraft wizadry Rowling],
  id: '00000001-3800-5555-9999-000000000002',
  courses: [courses.first, courses.third],
  items: [item1, item2]
)

DocumentLocalization.create!(
  title: 'Quidditch im Wandel der Zeiten',
  description: 'von J.K.R.',
  id: '00000001-3800-5555-9997-000000000004',
  document: document2,
  file_id: '00000001-4000-4444-9999-000000000008',
  language: 'de',
  revision: '1'
)

DocumentLocalization.create!(
  title: 'Quidditch through the Ages',
  description: 'A somewhat interesting book by J.K.R.',
  id: '00000001-3800-5555-9997-000000000005',
  document: document2,
  file_id: '00000001-4000-4444-9999-000000000008',
  language: 'en',
  revision: '1'
)

# #3##
document3 = Document.create!(
  title: 'The Tales of Beedle the Bard',
  description: 'A nice book by J.K.Rowling',
  tags: %w[fantasy tales witchcraft wizadry Rowling],
  id: '00000001-3800-5555-9999-000000000003',
  courses: [courses.first, courses.third, courses.fourth],
  items: [item2]
)

DocumentLocalization.create!(
  title: 'The Tales of Beedle the Bard',
  description: 'An interesting book by J.K.R.',
  id: '00000001-3800-5555-9997-000000000006',
  document: document3,
  file_id: '00000001-4000-4444-9999-000000000008',
  language: 'en',
  revision: '1'
)

# #4##
document4 = Document.create!(
  title: 'Harry Potter and the cursed child',
  description: 'Not a nice book and not by J.K.Rowling',
  tags: %w[fantasy witchcraft wizadry Rowling],
  id: '00000001-3800-5555-9999-000000000004',
  courses: [courses.second],
  items: [item1]
)

DocumentLocalization.create!(
  title: 'Harry Potter and the cursed child',
  description: 'An awful book',
  id: '00000001-3800-5555-9997-000000000007',
  document: document4,
  file_id: '00000001-4000-4444-9999-000000000008',
  language: 'en',
  revision: '0'
)

##### Course Prerequisites #####

track = CourseSet.create!(name: 'track')
track.courses << Course.by_identifier('cloud2013').take!

prereq1 = CourseSet.create!(name: 'prereq1')
prereq1.courses << Course.by_identifier('geo2013').take!

prereq2 = CourseSet.create!(name: 'prereq2-iter')
prereq2.courses << Course.by_identifier('sw-profiling2013').take!
prereq2.courses << Course.by_identifier('sw-profiling2015').take!

CourseSetRelation.create!(
  source_set: track,
  target_set: prereq1,
  kind: 'requires_cop'
)

CourseSetRelation.create!(
  source_set: track,
  target_set: prereq2,
  kind: 'requires_roa'
)

#
# Require additional seeds
#

Rails.root.glob('db/seeds/development/*.rb').sort.each do |file|
  load file
end

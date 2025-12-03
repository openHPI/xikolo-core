# frozen_string_literal: true

# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

NewsService::News.create!(
  id: '00000001-4300-4444-9999-000000000001',
  author_id: '00000001-3100-4444-9999-000000000002',
  course_id: '00000001-3300-4444-9999-000000000002',
  publish_at: Time.zone.now,
  translations: [NewsService::NewsTranslation.new(
    locale: 'en',
    title: 'Test Title for Geovisualisierung',
    text: '
Dear course participants,

We hope you enjoyed listening to the lectures, completing the self-test and weekly assignment of week 1, and that you are looking forward to week 2!
Before you start with week 2, please take a moment to review the following information:

Some more text too come....
'
  )]
)

NewsService::News.create!(
  id: '00000001-4300-4444-9999-000000000002',
  author_id: '00000001-3100-4444-9999-000000000002',
  publish_at: Time.zone.now,
  translations: [NewsService::NewsTranslation.new(
    locale: 'en',
    title: 'Some title',
    text: '
Dear course participants,

we hope you enjoy reading texts. Because here is one.
'
  )]
)

NewsService::News.create!(
  id: '00000001-4300-4444-9999-000000000003',
  author_id: '00000001-3100-4444-9999-000000000002',
  publish_at: Time.zone.now,
  translations: [NewsService::NewsTranslation.new(
    locale: 'en',
    title: 'Week 3 Begins Today',
    text: '
Dear course participants,

learners be learnin\'.
'
  )]
)

NewsService::News.create!(
  id: '00000001-4300-4444-9999-000000000004',
  author_id: '00000001-3100-4444-9999-000000000002',
  publish_at: Time.zone.now,
  show_on_homepage: true,
  translations: [NewsService::NewsTranslation.new(
    locale: 'en',
    title: 'Week 2 Begins Today',
    text: '
Dear course participants,

enjoy wisdom when you see it.
'
  )]
)

NewsService::News.create!(
  id: '00000001-4300-4444-9999-000000000005',
  author_id: '00000001-3100-4444-9999-000000000002',
  publish_at: Time.zone.now,
  show_on_homepage: true,
  translations: [NewsService::NewsTranslation.new(
    locale: 'en',
    title: 'Some title',
    text: '
Dear course participants,

reading is for readers.
'
  )]
)

NewsService::News.create!(
  id: '00000001-4300-4444-9999-000000000006',
  author_id: '00000001-3100-4444-9999-000000000002',
  publish_at: Time.zone.now,
  show_on_homepage: true,
  translations: [NewsService::NewsTranslation.new(
    locale: 'en',
    title: 'Week 2 Begins Today',
    text: "
Dear course participants,
We hope you are enjoying the course so far and welcome you to week 3.

__Week 2 assignment deadline:__
  * __Your assignment for week 2 is due on Monday November 11 at 10pm Central European Time (CET)__. (Find your time zone [here](http://www.timeanddate.com/worldclock/converted.html?iso=20131111T22&p1=83&p2=0&p3=136&p4=179&p5=197&p6=240&p7=213&p8=256&p9=438&p10=248&p11=155&p12=166)).
  * Once started, the weekly assignment will run for 60 minutes. It cannot be interrupted (not even by closing the browser window) and allows you to earn 30 points in week 2. These points are important if you want to earn a Record of Achievement for this course.

If you missed the deadline for week 1, don’t give up! You can still earn a Record of Achievement; you only need to earn a minimum total of 50% from all weekly assignments and the final exam. So get started now!

Please note that learning materials will now be available from Friday prior to the official course start date. However the weekly assignment will be available on Mondays. We hope this will allow you to enjoy a flexible learning experience.

__Content week 3:__

The topic for week 3 is Advanced Persistency Features. Here are the units you can look forward to:

  * Unit 1: Local Development
  * Unit 2: Using Modeler
  * Unit 3: Introduction to the Document Service
  * Unit 4: Consuming Document Service with External Tools
  * Unit 5: Document Service Metadata & Queries

Don’t forget, John Doe, one of our course instructors, has created a [blog](https://example.com/blog) which you can also follow throughout the course.

Good luck with week 3 and if you would like to discuss any content-related topics, please use our discussion forums for lively and interesting discussions. There is a separate discussion forum for each week of the course, and another \"General Discussions\" forum for broader topics that are not limited to the week-specific content.

__If you experience any technical issues with the platform, please use the Helpdesk function rather than the discussion forums. Our colleagues in support will be happy to help you.__

Wishing you continued learning success!

Your Course Team
"
  )]
)

NewsService::News.create!(
  id: '00000001-4300-4444-9999-000000000007',
  author_id: '00000001-3100-4444-9999-000000000002',
  publish_at: Time.zone.now,
  show_on_homepage: true,
  translations: [NewsService::NewsTranslation.new(
    locale: 'en',
    title: 'Some title',
    text: '
Dear course participants,

We hope you enjoyed listening to the lectures, completing the self-test and weekly assignment of week 1, and that you are looking forward to week 2!
Before you start with week 2, please take a moment to review the following information:

__Weekly Assignment Deadline Week 1__

Don’t forget the deadline of the weekly assignment – Week 1: Tuesday, November 19, 2013, 10 pm Central European Time (CET). Please try to submit the weekly assignment as early as possible to avoid overloading the system and last minute issues.

__Weekly Schedule__

Officially, the course runs from Monday through Monday. To allow you more flexibility with your learning schedule, the material of this course (videos, slides, self-tests) will always be available from Friday of the previous week.
However, the weekly assignments will only be accessible from Monday of the course week and the deadlines for the assignments will be on Tuesday of the following week. We hope this is beneficial for you and your schedule.

__For week 2 this means:__

  * Material is available from Friday, November 15, 9 am Central European Time (CET)
  * Weekly Assignment Access: From Monday, November 18, 9 am Central European Time (CET) until the deadline Tuesday, November 26, 2013, 10 pm Central European Time (CET). [You can check your time zone here](http://www.timeanddate.com/worldclock/converted.html?iso=20131126T22&p1=83&p2=240&p3=213&p4=256&p5=438&p6=248&p7=155&p8=166&p9=111&p10=179&p11=776&p12=0).
  * You can always check the countdown on the [course page](http://example.com/courses) to see how much time is left until the next deadline.

__Forum Discussions__

The forum is a useful tool to meet fellow students and BI experts. Many of you have been very active in week 1, and we would like to thank you for posting questions and helping your fellow students. Please be sure to post your content in the section where it belongs – there is a general discussion forum and one forum per week. We recommend that you search the forum using the search bar on the top left of the discussion forum before you start a new thread. The answer you’re looking for might already exist in the forum, answering your question faster and avoiding duplication in the forum.

__Workload in Week 2__

Week 2 deals with the topic _Installation, Upgrade and Promotion_.

  * Unit 1: Installation
  * Unit 2: Configuration
  * Unit 3: Upgrade
  * Unit 4: Promotion

__Additional Downloads:__

For week 2 you find 1 additional resource package in the [download section](https://example.com/courses/9/modules/items/441:

  * Week_2_Exercises.zip. Contains 4 Exercises for Week 2

Enjoy learning in week 2!

The Course Team
'
  )]
)

NewsService::News.create!(
  id: '00000001-4300-4444-9999-000000000008',
  author_id: '00000001-3100-4444-9999-000000000002',
  publish_at: Time.zone.now,
  show_on_homepage: true,
  translations: [NewsService::NewsTranslation.new(
    locale: 'en',
    title: 'Week 2 Begins Today',
    text: '
Dear course participants,

lorem ipsum cannot be boring.
'
  )]
)

NewsService::News.create!(
  id: '00000001-4300-4444-9999-000000000009',
  author_id: '00000001-3100-4444-9999-000000000002',
  publish_at: Time.zone.now,
  show_on_homepage: true,
  translations: [NewsService::NewsTranslation.new(
    locale: 'en',
    title: 'Some title',
    text: '
Dear course participants,

lirum larum. The quick red brown fox slowly ate some drinks.
'
  )]
)

NewsService::Announcement.create!(
  author_id: '00000001-3100-4444-9999-000000000002',
  recipients: [],
  translations: {
    'en' => {
      subject: 'Announcing the big Xikolo Holiday Promotion',
      content: '
Dear Xikolo users,

We have reached 12 trillion registered (bot) users. As a thank you, we want to celebrate!

From January 1 to December 31, get 200% off on course reactivations and zero-work certificates. Redeem your voucher now!
',
    },
  }
).tap do |announcement|
  announcement.messages.create!(
    creator_id: '00000001-3100-4444-9999-000000000002',
    status: 'sending',
    recipients: [],
    translations: {
      'en' => {
        subject: 'Announcing the big Xikolo Holiday Promotion',
        content: '
Dear Xikolo users,

We have reached 12 trillion registered (bot) users. As a thank you, we want to celebrate!

From January 1 to December 31, get 200% off on course reactivations and zero-work certificates. Redeem your voucher now!
',
      },
    }
  )
end

NewsService::Announcement.create!(
  author_id: '00000001-3100-4444-9999-000000000002',
  recipients: [],
  translations: {
    'en' => {
      subject: 'Announcing new partner offers',
      content: '
Dear Xikolo users,

in addition to our course offerings, you can now participate in on-site events close to you.

For this, please sign up on our website.
',
    },
  }
).tap do |announcement|
  announcement.messages.create!(
    creator_id: '00000001-3100-4444-9999-000000000002',
    status: 'sending',
    recipients: [],
    consents: %w[treatment.marketing],
    translations: {
      'en' => {
        subject: 'Announcing new partner offers',
        content: '
Dear Xikolo users,

in addition to our course offerings, you can now participate in on-site events close to you.

For this, please sign up on our website.
',
      },
    }
  )
end

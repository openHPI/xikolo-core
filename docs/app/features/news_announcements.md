# News and Announcements Setup Documentation

## Overview

This application provides a multi-level announcements management system with three controller layers:

- **Course Announcements**: Course-specific announcements
- **Global Announcements**: Announcements for targeted user groups
- **Global News**: Plattform wide notification. Sends email to all users with an option to highlight news on the Homepage

### Feature Flag

- Enable the `admin_announcements` feature flag to access announcement management functionality

### User Permissions required to write, update or publish Announcements

The following permissions control access to announcement features:

- `news.announcement.create` - Create new announcements as a draft
- `news.announcement.update` - Edit draft/unpublished announcements
- `news.announcement.delete` - Delete announcements
- `news.announcement.show` - View draft/unpublished announcements
- `news.announcement.send` - Send announcement via email notifications to defined group of users
- `news.announcement.send_test` - Send test email notifications

### API Integration (deprecated)

API Integration via micro service is deprecated please use monolith approach.

- Configure the `news` API service via `Xikolo.api(:news)`
- Ensure the API supports the following endpoints:
  - `/announcements` - List and create global announcements
  - `/announcement/{id}` - Get, update individual announcements
  - `/news_index` - List course announcements
  - `/news/{id}` - Get, update, delete course announcements
  - `/{id}/email` - Send email notifications

### Monolith approach

Use NewsService (engine) for news and announcement.

```ruby
  # create a news
   NewsService::News.create!(
    id: '00000001-4300-4444-9999-000000000008',
    author_id: '00000001-3100-4444-9999-000000000002',
    publish_at: Time.zone.now,
    show_on_homepage: false,
    translations: [NewsService::NewsTranslation.new(
        locale: 'en',
        title: 'Check this out',
        text: 'Dear openHPI user, here are some super interesting news for you.'
    )]
  )
```

```ruby
  # create a announcement
  NewsService::Announcement.create!(
    author_id: '00000001-3100-4444-9999-000000000002',
    recipients: [],
    translations: {
        'en' => {
        subject: 'Did you know',
        content: 'Dear Course users, this course got renewed for you.',
        },
    }
  )
```

### Key Features

- Draft/Published state management via `publication_channels` (currently we only support email channel)
- Course context authorization via `inside_course` helper method defined in `CourseContextHelper`
- Email notification system for announcement publishing
- Test email capability for announcement authors

## Announcement Content

### Announcement - Create

Always creates a Draft

- Subject (email subject)
- Content (email body)
- Optional: Subject and Content with German translation

### Announcement - Edit and Publish

Additional setup for announcement drafts

- Recipients (user name, email, course title or course code)
- Optional: Consents (highly recommended)

Send test email or send announcement emails to all recipients that have given the selected consents.

### Announcement - View statistics

Available when announcement is published
Overview of successful/failed email sends as well as email open rate.

### Announcement - Consent and Preferences

Next to the defined consent of an announcements, each recipient needs to have notification preferences enabled in the profile.

- `CourseAnnouncements` (recipients of a course) require `notification.email.course.announcement`.
- Announcements that are not course related are `GlobalAnnouncement` and require `notification.email.news.announcement` instead

Both notification prefences can only be defined true if `notification.email.global` is enabled.

## Global News

### News - Create and Edit

Create and edit view are very similar. Target group can't be changed for published news.

- Title (email subject)
- Text (email body)
- Publish at UTC
- Show on homepage
- Optional: Visual
- Optional: Target group (all users as default)
- Optional: Subject and Content with German translation

Send test email or send news emails to all recipients in the given group.

### News - Banner on homepage

Up to three news banners visible on the homepage. Displaying the news Title and Text (character cap). Banner links to news page.

### News - View statistics

No native statistic view implemented.

### News - Consent and Preferences

News take notification preference `notification.email.global` into account. See `NewsController`.

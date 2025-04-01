# frozen_string_literal: true

module Steps
  module News
    module Content
      def create_news
        context.with :user do
          admin = create_user admin: true

          data = {
            author_id: admin.fetch('id'),
            publish_at: DateTime.now,
            show_on_homepage: true,
            title: 'Test Title',
            text: 'Test text',
          }

          Server[:news].api.rel(:news_index).post(data).value!
        end
      end

      def create_announcement
        context.with :user do
          admin = create_user admin: true

          Server[:news].api.rel(:announcements).post({
            author_id: admin.fetch('id'),
            translations: {
              en: {
                subject: 'Join our new course on MOOCs!',
                content: 'You already took our first course - now join the second one.',
              },
            },
          }).value!
        end
      end

      Given 'a global announcement was created' do
        context.assign :announcement, create_news
      end

      Given 'the announcement was sent' do
        context.with :announcement do |announcement|
          announcement.rel(:email).post.value!
        end
      end

      Given 'a targeted announcement was created' do
        context.assign :announcement, create_announcement
      end
    end
  end
end

Gurke.configure {|c| c.include Steps::News::Content }

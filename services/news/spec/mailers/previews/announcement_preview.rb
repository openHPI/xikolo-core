# frozen_string_literal: true

# Preview all emails at http://localhost:4300/rails/mailers/announcement
class AnnouncementPreview < ActionMailer::Preview
  def announcement_de
    AnnouncementMailer.announcement(message, user('de'))
  end

  def announcement_en
    AnnouncementMailer.announcement(message, user('en'))
  end

  def announcement_pt
    AnnouncementMailer.announcement(message, user('pt'))
  end

  def announcement_test
    AnnouncementMailer.announcement(message(test: true), user('en'))
  end

  private

  def message(test: false)
    content = <<~CONTENT
      # Headline 1
      ## Headline 2
      ### Headline 3
      #### Headline 4
      ##### Headline 5

      Some text,

      Et consectetur perspiciatis necessitatibus ea temporibus quibusdam a. Qui expedita esse unde occaecati voluptatum. Voluptatum voluptates fugit quia. Ut officia nostrum qui.

      Omnis perspiciatis officia neque. Sunt nemo qui quod aut odit rerum. Velit quasi amet eius quasi deleniti sed. Nihil excepturi aut facere facilis consequatur voluptate nisi vel. Aut eius in at.

      Maxime eum non deserunt et asperiores ut et. Provident expedita officia ea. Nesciunt autem voluptas ex dicta aut. Dolores facilis quo vitae in repellendus assumenda vitae sint.

      Sapiente possimus repellat autem ullam molestias sed laborum. Quisquam dolore iste sint nisi. Et inventore aut fugit. Qui error perferendis deleniti quidem.

      Voluptatum rem fuga voluptas. Et dolor repellat corrupti. Quis iure blanditiis ut rem doloribus provident iusto. Sequi ut ad aut. Ut sit rem rerum iusto dicta dolor blanditiis. Illum non nulla saepe voluptas quia.


      **strong text**

      *emphasized text*

      > Blockquote

      [Link description](www.example.com)

          enter code here

      - List
      - List
      - List

      1. List
      2. List
      3. List
    CONTENT

    Message.new(
      announcement_id: Announcement.new.id,
      recipients: %w[urn:x-xikolo:account:user:the.user],
      translations: {
        en: {subject: 'Test Subject', content:},
        de: {subject: 'Test Subject', content: '**Wichtig:** Du wirst *meine News* mögen...'},
      },
      test:,
      status: 'sending'
    )
  end

  def user(language)
    {
      id: '00000001-3100-4444-9999-000000000002',
      email: 'to@example.org',
      language:,
    }.stringify_keys
  end
end

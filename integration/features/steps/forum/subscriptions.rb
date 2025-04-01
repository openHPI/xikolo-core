# frozen_string_literal: true

module Steps::Forum::Subscriptions
  Given 'the topic has subscribers' do
    topic = context.fetch :forum_topic
    subscribers = Factory.create_list(:user, 2)
    subscribers = subscribers.map do |userdata|
      user = Server[:account].api.rel(:users).post(userdata).value!
      Server[:pinboard].api.rel(:subscriptions).post({
        user_id: user['id'],
        question_id: topic['id'],
      }).value!
      user
    end
    context.assign :forum_topic_subscribers, subscribers
  end

  Given 'I am subscribed to the current topic' do
    context.with :user, :forum_topic do |user, topic|
      Server[:pinboard].api.rel(:subscriptions).post({
        user_id: user['id'],
        question_id: topic['id'],
      }).value!
    end
  end

  When 'I subscribe to the current topic' do
    click_on 'Follow'
    sleep 0.1
  end

  When 'I unsubscribe from the current topic' do
    wait_for_ajax
    click_on 'Unfollow'
    sleep 0.1
  end

  Then 'every subscriber received a comment notification email' do
    context.with :user, :forum_topic_subscribers do |author, subscripters|
      subscripters.each do |subscriber|
        open_email fetch_emails(to: subscriber['email']).last
        expect(page).to have_content "#{author['name']} posted in a topic you are following"
      end
    end
  end

  Then 'every subscriber received an answer notification email' do
    context.with :user, :forum_topic_subscribers do |author, subscripters|
      subscripters.each do |subscriber|
        open_email fetch_emails(to: subscriber['email']).last
        expect(page).to have_content "#{author['name']} posted in a topic you are following"
      end
    end
  end

  When 'every subscriber received a comment notification email' do
    send :'Then every subscriber received a notification email'
  end

  When 'every subscriber received an answer notification email' do
    send :'Then every subscriber received an answer notification email'
  end

  When 'I click on the topic link' do
    context.with :forum_topic do |topic|
      click_on topic['title']
    end
  end

  When 'I open my forum notification email' do
    context.with :user do |user|
      open_email fetch_emails(
        to: user['email'],
        subject: 'New post in a topic you are following: A Course :-)'
      ).last
    end
  end

  Then 'the topic is added to my subscribed topics' do
    context.with :user, :forum_topic do |user, topic|
      subscriptions = Server[:pinboard].api.rel(:subscriptions).get({
        user_id: user['id'],
        question_id: topic['id'],
      }).value!
      expect(subscriptions.size).to eq 1
    end
  end

  Then 'the topic is removed from my subscribed topics' do
    context.with :user, :forum_topic do |user, topic|
      subscriptions = Server[:pinboard].api.rel(:subscriptions).get({
        user_id: user['id'],
        question_id: topic['id'],
      }).value!
      expect(subscriptions.size).to eq 0
    end
  end

  Then 'the topic shows a note that I am subscribed to it' do
    expect(page).to have_css 'span.fa-star.fa-solid'
  end

  Then 'the topic shows a note that I am not subscribed to it' do
    expect(page).to have_css 'span.fa-star.fa-regular'
  end

  Then 'I see a follow button' do
    expect(page).to have_link 'Follow'
  end

  Then 'I see an unfollow button' do
    expect(page).to have_link 'Unfollow'
  end

  Then 'the topic is not listed under subscribed topics anymore' do
    context.with :forum_topic do |topic|
      expect(page).to_not have_content topic['title']
    end
  end
end

Gurke.configure {|c| c.include Steps::Forum::Subscriptions }

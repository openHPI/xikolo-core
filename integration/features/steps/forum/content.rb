# frozen_string_literal: true

module Steps::Forum::Content
  def create_forum_topic(attrs)
    course = context.fetch :course
    data = {
      title: 'A Very (VERY) important question',
      text: 'I have no idea what to ask.',
      course_id: course['id'],
    }

    data.merge! attrs
    data.compact!

    Server[:pinboard].api.rel(:questions).post(data)
  end

  def create_forum_tag(attrs = {})
    course = context.fetch :course
    data = {
      name: 'Homework',
      course_id: course['id'],
    }
    data.merge! attrs
    data.compact!

    Server[:pinboard].api.rel(:explicit_tags).post(data).value!
  end

  def vote(votable, votable_type, user, value)
    Server[:pinboard].api.rel(:votes).post({
      value:,
      votable_id: votable['id'],
      votable_type:,
      user_id: user['id'],
    })
  end

  def post_topic(author, section = nil, item = nil)
    course = context.fetch :course
    context.assign :forum_topic_author, author
    implicit_tags = nil
    if section
      implicit_tags = [Server[:pinboard].api.rel(:implicit_tag).get({
        name: section['id'],
        course_id: course['id'],
        referenced_resource: 'Xikolo::Course::Section',
      }).value![0]['id']]
    end
    if item
      implicit_tags << Server[:pinboard].api.rel(:implicit_tag).get({
        name: item['id'],
        course_id: course['id'],
        referenced_resource: 'Xikolo::Course::Item',
      }).value![0]['id']
    end

    topic = create_forum_topic(user_id: author['id'], implicit_tags:).value!
    context.assign :forum_topic, topic
    enrollment = {
      user_id: author['id'],
      course_id: course['id'],
      role: 'student',
    }
    Server[:course].api.rel(:enrollments).post(enrollment).value!
  end

  def answer_topic(topic, answering_user, attrs = {})
    data = {
      question_id: topic['id'],
      user_id: answering_user['id'],
      text: 'I think I know the answer: 42!',
    }

    data.merge! attrs
    data.compact!

    Server[:pinboard].api.rel(:answers).post(data).value!
  end

  def update_topic(data)
    topic = context.fetch :forum_topic
    params = {id: topic['id'], text: topic['text']}
    Server[:pinboard].api.rel(:question).patch(data, params:)
  end

  Given 'a topic is posted in the general forum' do
    post_topic create_user
  end

  Given 'somebody posted a topic' do
    post_topic create_user
  end

  Given 'a topic is posted in the section\'s forum' do
    post_topic create_user, context.fetch(:section)
  end

  Given 'I posted a topic in the general forum' do
    post_topic context.fetch :user
  end

  Given 'I posted a topic in the section\'s forum' do
    post_topic context.fetch(:user), context.fetch(:section)
  end

  Given 'a topic is posted in the section\'s forum' do
    post_topic create_user, context.fetch(:section)
  end

  Given 'a video topic exists' do
    context.with :section, :item do |section, item|
      post_topic create_user, section, item
    end
  end

  Given 'the topic is deleted' do
    update_topic deleted: true
  end

  Given 'the topic is blocked' do
    update_topic workflow_state: 'blocked'
  end

  Given 'the topic is reviewed' do
    update_topic workflow_state: 'reviewed'
  end

  Given 'the topic has an answer' do
    topic = context.fetch :forum_topic
    answering_user = create_user
    answer = answer_topic(topic, answering_user)
    context.assign :forum_topic_answer, answer
  end

  Given(/^someone (?:replied|answered the topic)/) do
    topic = context.fetch :forum_topic
    answering_user = create_user
    text = 'First answer'
    @answer = answer_topic(topic, answering_user, text:)
  end

  Given(/^(\d*) seconds later yet another person replies/) do |so_many|
    the_time = so_many.to_i.seconds.from_now
    topic = context.fetch :forum_topic
    answering_user = create_user
    text = 'Another answer'
    answer_topic(topic, answering_user, text:, updated_at: the_time)
  end

  Given 'the topic has an answer with notification' do
    topic = context.fetch :forum_topic
    answering_user = create_user
    answer = answer_topic(topic, answering_user, notification: {notify: true})
    context.assign :forum_topic_answer, answer
  end

  Given 'I answered the topic' do
    context.with :user, :forum_topic do |user, topic|
      answering_user = create_user
      answer = answer_topic(topic, answering_user,
        user_id: user['id'],
        notification: {
          notify: true,
          question_url: "#{Capybara.app_host}/courses/the_course/question/#{topic['id']}",
        })
      context.assign :forum_topic_answer, answer
    end
  end

  def create_comment(commentable, type, attrs = {})
    commenting_user = create_user

    data = {
      notification: {notify: true},
      commentable_id: commentable['id'],
      user_id: commenting_user['id'],
      text: 'You should figure that out first!',
      commentable_type: type,
    }
    data.merge! attrs
    data.compact!

    Server[:pinboard].api.rel(:comments).post(data).value!
  end

  def comment_with_notification(commentable, type, user)
    question_id = if type == 'Question'
                    commentable['id']
                  else
                    commentable['question_id']
                  end
    create_comment(commentable, type,
      user_id: user['id'],
      notification: {
        notify: true,
        question_url: "#{Capybara.app_host}/courses/the_course/question/#{question_id}",
      })
  end
  Given 'the topic has a comment' do
    topic = context.fetch :forum_topic
    comment = create_comment(topic, 'Question')
    context.assign :forum_topic_comment, comment
  end

  Given 'then someone wrote a comment on that topic' do
    topic = context.fetch :forum_topic
    create_comment(topic, 'Question', text: 'First comment')
  end

  Given(/someone commented this answer/) do
    create_comment(@answer, 'Answer', text: 'First comment')
  end

  Given 'after a while there is a new comment to the topic' do
    the_time = 1.minute.from_now
    topic = context.fetch :forum_topic
    create_comment(topic, 'Question', updated_at: the_time, text: 'Another comment')
  end

  Given 'after a while there is a new comment to this answer' do
    the_time = 1.minute.from_now
    create_comment(@answer, 'Answer', updated_at: the_time, text: 'Another comment')
  end

  Given 'I commented on the topic' do
    context.with :user, :forum_topic do |user, topic|
      comment = comment_with_notification(topic, 'Question', user)
      context.assign :comment, comment
    end
  end

  Given 'I commented the answer' do
    context.with :user, :forum_topic_answer do |user, answer|
      comment = comment_with_notification(answer, 'Answer', user)
      context.assign :comment, comment
    end
  end

  Given 'the answer has a comment' do
    answer = context.fetch :forum_topic_answer
    comment = create_comment(answer, 'Answer')
    context.assign :forum_answer_comment, comment
  end

  Given 'the topic receives a comment' do
    send :'Given the topic has a comment'
  end

  Given 'the topic has a comment by me' do
    context.with :forum_topic, :user do |topic, user|
      comment = create_comment(topic, 'Question', user_id: user['id'])
      context.assign :forum_topic_comment, comment
    end
  end

  Given 'the answer has a comment by me' do
    context.with :forum_topic_answer, :user do |answer, user|
      comment = create_comment(answer, 'Answer', user_id: user['id'])
      context.assign :forum_answer_comment, comment
    end
  end

  Given 'the topic has an upvote' do
    topic = context.fetch :forum_topic
    user = create_user
    vote(topic, 'Question', user, 1).value!
  end

  Given 'the topic has an downvote' do
    topic = context.fetch :forum_topic
    user = create_user
    vote(topic, 'Question', user, -1).value!
  end

  Given 'the forum is filled with topics' do
    course = context.fetch :course

    tag = create_forum_tag
    context.assign :forum_tag, tag
    tags = %w[SQL Databases ACID] << tag['name']

    # Create enough topics to fill three pages and give each one
    # an unique author, random tags and varying number of votes
    authors = Factory.create_list(:user, 55).map do |data|
      Server[:account].api.rel(:users).post(data)
    end.map(&:value!)

    topics = authors.each_with_index.map do |author, index|
      payload = Factory.create(
        :forum_topic,
        course_id: course['id'],
        user_id: author['id'],
        tag_names: tags.sample(rand(tags.size))
      )

      Server[:pinboard].api.rel(:questions).post(payload).then do |topic|
        # 1, -1, 2, -2, 3, -3...
        votes = (index / 2) + 1
        topic['votes'] = votes * (index.even? ? 1 : -1)

        Restify::Promise.new(
          Array.new(votes) do |i|
            vote(topic, 'Question', authors[i], index.even? ? 1 : -1)
          end
        ) { topic }
      end.value!
    end

    context.assign :forum_topics, topics
  end

  Given 'an explicit tag was created' do
    context.assign :forum_tag, create_forum_tag
  end

  When 'the topic is answered' do
    send :'Given the topic has an answer'
  end

  When 'the topic is voted on' do
    send :'Given the topic has an downvote'
    send :'Given the topic has an upvote'
    send :'Given the topic has an upvote'
    visit page.driver.browser.current_url
  end

  When 'the topic is answered and commented' do
    send :'Given the topic has an answer'
    send :'Given the topic has a comment'
    visit page.driver.browser.current_url
  end
end

Gurke.configure {|c| c.include Steps::Forum::Content }

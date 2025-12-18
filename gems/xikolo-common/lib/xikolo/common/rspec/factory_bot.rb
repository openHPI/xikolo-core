# frozen_string_literal: true

if defined? FactoryBot
  class FactoryBot::Syntax::Default::DSL
    def xikolo_uuid_sequence(name, args)
      service = args.fetch(:service).to_i
      resource = args.fetch(:resource).to_i
      sequence(name) {|i| format('81e01000-%d-4444-a%03d-0000000%05d', service, resource, i) }
    end
  end

  FactoryBot.define do # rubocop:disable Metrics/BlockLength
    xikolo_uuid_sequence(:user_id,     service: 3100, resource: 1)
    xikolo_uuid_sequence(:context_id,  service: 3100, resource: 2)
    xikolo_uuid_sequence(:group_id,    service: 3100, resource: 3)
    xikolo_uuid_sequence(:session_id,  service: 3100, resource: 4)

    xikolo_uuid_sequence(:course_id,   service: 3300, resource: 1)
    xikolo_uuid_sequence(:section_id,  service: 3300, resource: 2)
    xikolo_uuid_sequence(:item_id,     service: 3300, resource: 3)

    xikolo_uuid_sequence(:richtext_id, service: 3700, resource: 1)

    xikolo_uuid_sequence(:quiz_id,     service: 3800, resource: 1)
    xikolo_uuid_sequence(:question_id, service: 3800, resource: 2)

    xikolo_uuid_sequence(:file_id,     service: 4000, resource: 1)

    factory 'account:root', class: Hash do
      session_url	{ '/account_service/sessions/{id}{?embed,context}' }
      sessions_url { '/account_service/sessions' }

      treatment_url { '/account_service/treatments/{id}' }
      treatments_url { '/account_service/treatments' }

      user_url { '/account_service/users/{id}' }
      user_ban_url { '/account_service/users/{user_id}/ban' }
      users_url { '/account_service/users{?search,query,archived,confirmed,id,permission,context,auth_uid}' }

      email_suspensions_url { '/account_service/emails/{address}/suspend' }
      email_url { '/account_service/emails/{id}' }

      password_reset_url { '/account_service/password_resets/{id}' }
      password_resets_url { '/account_service/password_resets' }

      policies_url { '/account_service/policies' }

      statistics_url { '/account_service/statistic' }

      authorization_url	{ '/account_service/authorizations/{id}' }
      authorizations_url	{ '/account_service/authorizations{?provider,uid,user}' }

      group_url { '/account_service/groups/{id}' }
      groups_url { '/account_service/groups{?user,tag,prefix}' }

      grants_url { '/account_service/grants{?role,context}' }

      context_url { '/account_service/contexts/{id}' }
      contexts_url { '/account_service/contexts{?ancestors,ascent}' }

      membership_url { '/account_service/memberships/{id}' }
      memberships_url { '/account_service/memberships' }

      role_url { '/account_service/roles/{id}' }
      roles_url { '/account_service/roles' }

      system_info_url { '/account_service/system_info/{id}' }

      token_url { '/account_service/tokens/{id}' }
      tokens_url { '/account_service/tokens{?token}' }

      initialize_with { attributes.as_json }
    end

    factory 'course:root', class: Hash do
      items_current_url { '/items/current' }
      item_user_visit_url { '/items/{item_id}/users/{user_id}/visit' }
      item_user_results_url { '/items/{item_id}/users/{user_id}/results' }
      item_results_url { '/items/{item_id}/results' }
      items_url { '/items' }
      item_url { '/items/{id}{?embed,user_id,version_at,for_user}' }
      result_url { '/results/{id}' }
      course_statistic_url { '/courses/{course_id}/statistic' }
      course_persist_ranking_task_url { '/courses/{course_id}/persist_ranking_task' }
      course_documents_url { '/courses/{course_id}/documents' }
      course_learning_evaluation_url { '/courses/{course_id}/learning_evaluation' }
      courses_url do
        '/courses{?cat_id,user_id,status,id,lang,course_code,upcoming,per_page,current,' \
          'finished,public,hidden,onlude_external,latest_first,alphabetic,promoted_for,' \
          'not_enrolled,middle_of_course,document_id,autocomplete,active_after,sort}'
      end
      course_url { '/courses/{id}' }
      documents_tags_url { '/documents_tags' }
      document_document_localizations_url { '/documents/{document_id}/document_localizations{?document_id}' }
      documents_url { '/documents{?course_id,item_id,language,tag}' }
      document_url { '/documents/{id}' }
      document_localizations_url { '/document_localizations{?document_id}' }
      document_localization_url { '/document_localizations/{id}' }
      channels_url { '/channels' }
      channel_url { '/channels/{id}' }
      next_dates_url { '/next_dates' }
      classifiers_url { '/classifiers' }
      classifier_url { '/classifiers/{id}' }
      sections_url { '/sections' }
      section_url { '/sections/{id}' }
      section_choices_url { '/section_choices' }
      enrollment_reactivations_url { '/enrollments/{enrollment_id}/reactivations' }
      enrollments_url do
        '/enrollments{?course_id,user_id,learning_evaluation,deleted,current_course,per_page,proctored}'
      end
      enrollment_url { '/enrollments/{id}' }
      teachers_url { '/teachers{?course,query}' }
      teacher_url { '/teachers/{id}' }
      richtext_url { '/richtexts/{id}' }
      system_info_url { '/system_info/{id}' }
      last_visit_url { '/last_visits/{course_id}' }
      prerequisite_status_url { '/courses/{id}/prerequisite_status{?user_id}' }
      progresses_url { '/progresses' }
      stats_url { '/stats' }
      enrollment_stats_url { '/enrollment_stats{?start_date,end_date,classifier_id}' }
      repetition_suggestions_url { '/repetition_suggestions' }
      api_v2_course_root_url { '/api/v2/course' }
      api_v2_course_courses_url { '/api/v2/course/courses{?embed,channel,document_id}' }
      api_v2_course_course_url { '/api/v2/course/courses/{id}{?embed,raw}' }
      initialize_with { attributes.as_json }
    end

    factory 'news:root', class: Hash do
      announcement_email_url { '/news_service/announcements/{announcement_id}/email' }
      announcement_messages_url { '/news_service/announcements/{announcement_id}/messages' }
      announcement_user_visit_url { '/news_service/announcements/{announcement_id}/user_visits/{user_id}' }
      announcements_url { '/news_service/announcements' }
      announcement_url { '/news_service/announcements/{id}' }
      message_url { '/news_service/messages/{id}' }
      posts_url { '/news_service/posts' }
      visits_url { '/news_service/visits' }
      news_index_url { '/news_service/news' }
      news_url { '/news_service/news/{id}' }
      system_info_url { '/news_service/system_info/{id}' }
      initialize_with { attributes.as_json }
    end

    factory 'notification:root', class: Hash do
      events_url { '/events{?course_id,include_expired,locale,only_global,user_id}' }
      mail_log_stats_url { '/mail_log_stats{?news_id}' }
      system_info_url { '/system_info/{id}' }
      initialize_with { attributes.as_json }
    end

    factory 'pinboard:root', class: Hash do
      comments_url { '/pinboard_service/comments' }
      comment_url { '/pinboard_service/comments/{id}' }
      answers_url { '/pinboard_service/answers' }
      answer_url { '/pinboard_service/answers/{id}' }
      questions_url { '/pinboard_service/questions' }
      question_url { '/pinboard_service/questions/{id}' }
      votes_url { '/pinboard_service/votes' }
      vote_url { '/pinboard_service/votes/{id}' }
      topics_url { '/pinboard_service/topics' }
      topic_url { '/pinboard_service/topics/{id}' }
      post_user_vote_url { '/pinboard_service/posts/{post_id}/user_votes/{id}' }
      post_url { '/pinboard_service/posts/{id}' }
      tags_url { '/pinboard_service/tags' }
      tag_url { '/pinboard_service/tags/{id}' }
      explicit_tags_url { '/pinboard_service/explicit_tags' }
      explicit_tag_url { '/pinboard_service/explicit_tags/{id}' }
      implicit_tags_url { '/pinboard_service/implicit_tags' }
      implicit_tag_url { '/pinboard_service/implicit_tags/{id}' }
      subscriptions_url { '/pinboard_service/subscriptions' }
      subscription_url { '/pinboard_service/subscriptions/{id}' }
      course_subscriptions_url { '/pinboard_service/course_subscriptions' }
      course_subscription_url { '/pinboard_service/course_subscriptions/{id}' }
      statistics_url { '/pinboard_service/statistics' }
      statistic_url { '/pinboard_service/statistics/{id}' }
      abuse_reports_url { '/pinboard_service/abuse_reports' }
      abuse_report_url { '/pinboard_service/abuse_reports/{id}' }
      system_info_url { '/pinboard_service/system_info/{id}' }
      initialize_with { attributes.as_json }
    end

    factory 'quiz:root', class: Hash do
      clone_quiz_url { '/quiz_service/quizzes/{id}/clone' }
      quizzes_url { '/quiz_service/quizzes' }
      quiz_url { '/quiz_service/quizzes/{id}' }
      questions_url { '/quiz_service/questions' }
      question_url { '/quiz_service/questions/{id}' }
      multiple_answer_questions_url { '/quiz_service/multiple_answer_questions' }
      multiple_answer_question_url { '/quiz_service/multiple_answer_questions/{id}' }
      multiple_choice_questions_url { '/quiz_service/multiple_choice_questions' }
      multiple_choice_question_url { '/quiz_service/multiple_choice_questions/{id}' }
      free_text_questions_url { '/quiz_service/free_text_questions' }
      free_text_question_url { '/quiz_service/free_text_questions/{id}' }
      essay_questions_url { '/quiz_service/essay_questions' }
      essay_question_url { '/quiz_service/essay_questions/{id}' }
      answers_url { '/quiz_service/answers' }
      answer_url { '/quiz_service/answers/{id}' }
      text_answers_url { '/quiz_service/text_answers' }
      text_answer_url { '/quiz_service/text_answers/{id}' }
      free_text_answers_url { '/quiz_service/free_text_answers' }
      free_text_answer_url { '/quiz_service/free_text_answers/{id}' }
      quiz_submissions_url { '/quiz_service/quiz_submissions' }
      quiz_submission_url { '/quiz_service/quiz_submissions/{id}' }
      quiz_submission_questions_url { '/quiz_service/quiz_submission_questions' }
      quiz_submission_free_text_answers_url { '/quiz_service/quiz_submission_free_text_answers' }
      quiz_submission_answers_url { '/quiz_service/quiz_submission_answers' }
      quiz_submission_selectable_answers_url { '/quiz_service/quiz_submission_selectable_answers' }
      quiz_submission_snapshots_url { '/quiz_service/quiz_submission_snapshots' }
      quiz_submission_snapshot_url { '/quiz_service/quiz_submission_snapshots/{id}' }
      user_quiz_attempts_url { '/quiz_service/user_quiz_attempts' }
      submission_statistic_url { '/quiz_service/submission_statistics/{id}' }
      submission_question_statistic_url { '/quiz_service/submission_question_statistics/{id}' }
      quiz_submission_statistic_url { '/quiz_service/quiz_submission_statistics/{id}' }
      system_info_url { '/quiz_service/system_info/{id}' }
      initialize_with { attributes.as_json }
    end

    factory 'timeeffort:root', class: Hash do
      items_url { 'timeeffort_service/items{?section_id,course_id}' }
      item_url { 'timeeffort_service/items/{id}' }
      item_overwritten_time_effort_url { 'timeeffort_service/items/{item_id}/overwritten_time_effort' }
      initialize_with { attributes.as_json }
    end

    factory 'lanalytics:root', class: Hash do
      metric_url { '/metrics/{name}' }
      metrics_url { '/metrics' }
      report_jobs_url { '/report_jobs{?job_params,task_type,user_id,show_expired}' }
      report_job_url { '/report_jobs/{id}' }
      report_types_url { '/report_types' }
      course_statistics_url { '/course_statistics' }
      course_statistic_url { '/course_statistics/{id}' }
      system_info_url { '/system_info/{id}' }
      initialize_with { attributes.as_json }
    end
  end
end

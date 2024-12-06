# frozen_string_literal: true

class RootController < ApplicationController
  respond_to :json

  def index
    expires_in 5.minutes, public: true

    response.headers['Vary'] = %w[Host Accept]

    respond_with routes
  end

  private
  def routes
    {
      items_current_url: items_current_rfc6570,
      item_user_visit_url: item_user_visit_rfc6570,
      item_user_results_url: item_user_results_rfc6570,
      item_results_url: item_results_rfc6570,
      items_url: items_rfc6570,
      item_url: item_rfc6570,
      result_url: result_rfc6570,
      course_statistic_url: course_statistic_rfc6570,
      course_persist_ranking_task_url: course_persist_ranking_task_rfc6570,
      course_documents_url: course_documents_rfc6570,
      course_learning_evaluation_url: course_learning_evaluation_rfc6570,
      courses_url: courses_rfc6570,
      course_url: course_rfc6570,
      documents_tags_url: documents_tags_rfc6570,
      document_document_localizations_url:
        document_document_localizations_rfc6570,
      documents_url: documents_rfc6570,
      document_url: document_rfc6570,
      document_localizations_url: document_localizations_rfc6570,
      document_localization_url: document_localization_rfc6570,
      channels_url: channels_rfc6570,
      channel_url: channel_rfc6570,
      next_dates_url: next_dates_rfc6570,
      classifiers_url: classifiers_rfc6570,
      classifier_url: classifier_rfc6570,
      sections_url: sections_rfc6570,
      section_url: section_rfc6570,
      section_choices_url: section_choices_rfc6570,
      enrollment_reactivations_url: enrollment_reactivations_rfc6570,
      enrollments_url: enrollments_rfc6570,
      enrollment_url: enrollment_rfc6570,
      teachers_url: teachers_rfc6570,
      teacher_url: teacher_rfc6570,
      richtext_url: richtext_rfc6570,
      system_info_url: system_info_rfc6570,
      last_visit_url: last_visit_url_rfc6570,
      prerequisite_status_url: prerequisite_status_course_url_rfc6570,
      progresses_url: progresses_rfc6570,
      stats_url: stats_rfc6570,
      enrollment_stats_url: enrollment_stats_rfc6570,
      repetition_suggestions_url: repetition_suggestions_rfc6570,
      api_v2_course_root_url: api_v2_course_root_rfc6570,
      api_v2_course_courses_url: api_v2_course_courses_rfc6570,
      api_v2_course_course_url: api_v2_course_course_rfc6570,
      root_url: root_rfc6570,
    }
  end
end

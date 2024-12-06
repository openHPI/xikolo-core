# frozen_string_literal: true

class Admin::ReportsController < Abstract::FrontendController
  require_permission 'lanalytics.report.create'

  def index
    # the reports jobs table is rendered asynchronously via ajax
    if request.xhr?
      jobs = lanalytics_api
        .rel(:report_jobs)
        .get(user_id: current_user.id, per_page: 200)
        .value!
        .map {|job| Admin::ReportJobPresenter.new job, current_user }

      response.set_header('Cache-Control', 'no-store')

      return render partial: 'admin/reports/jobs', locals: {report_jobs: jobs}
    end

    @reports = report_types.map {|report| Admin::ReportPresenter.new(report, courses, classifiers, prefill_params) }
  end

  def create
    if params[:restart_id] # restart an existing report job
      begin
        authorize! 'lanalytics.report.delete'

        job = lanalytics_api.rel(:report_job).get(id: params[:restart_id]).value!

        create_report_job!(
          current_user.id,
          job['task_type'],
          job['task_scope'],
          job['options']
        )

        destroy_report_job!(
          job['id'],
          current_user.id
        )

        add_flash_message :success, t(:'reports.restarted')
        redirect_to reports_path
      rescue Restify::ResponseError
        add_flash_message :error, t(:'reports.not_restarted')
        redirect_to reports_path
      end
    else # create a new report job
      begin
        create_report_job!(
          current_user.id,
          report_params[:task_type],
          report_params[:task_scope]&.strip,
          task_options.as_json
        )

        add_flash_message :success, t(:'reports.created')
        redirect_to reports_path(
          report_type: report_params[:task_type],
          report_scope: report_params[:task_scope],
          **sanitized_task_options
        )
      rescue Restify::ResponseError
        add_flash_message :error, t(:'reports.not_created')
        redirect_to reports_path
      end
    end
  end

  def destroy
    authorize! 'lanalytics.report.delete'

    destroy_report_job!(
      params[:id],
      current_user.id
    )

    add_flash_message :success, t(:'reports.deleted')
    redirect_to reports_path
  rescue Restify::ResponseError
    add_flash_message :error, t(:'reports.not_deleted')
    redirect_to reports_path
  end

  private

  def create_report_job!(user_id, task_type, task_scope, task_options)
    lanalytics_api.rel(:report_jobs).post(
      user_id:,
      task_type:,
      task_scope:,
      options: task_options
    ).value!
  end

  def destroy_report_job!(job_id, user_id)
    job = lanalytics_api.rel(:report_job).get(id: job_id).value!

    raise Status::Unauthorized unless job['user_id'] == user_id

    lanalytics_api.rel(:report_job).delete(id: job_id).value!
  end

  def report_params
    params.require(submitted_form).permit(:task_type, :task_scope, options: report_params_options)
  end

  def prefill_params
    params.permit(:report_type, :report_scope, *report_params_options)
  end

  def report_types
    @report_types ||= lanalytics_api.rel(:report_types).get.value!
  end

  def submitted_form
    report_types.pluck('type').find {|type| params.key?(type) }
  end

  def report_params_options
    report_types.map do |report|
      report['options'].map {|option| option['name'].to_sym }
    end.flatten.uniq
  end

  # Checkbox values are submitted as '0' or '1', and the string '0' is truthy in Ruby. Therefore, we need to cast those
  # values to Boolean, so they can be properly encoded on the request body.
  # Also, `.to_h` is called twice for the following method because `report_params[:options]` is an
  # ActionController::Parameters instance, and the ability to call `.to_h` to reconstruct the hash based on a condition
  # is only possible with the core Ruby Hash class.
  def task_options
    report_params[:options].to_h.to_h do |key, value|
      if checkbox_options.include?(key)
        [key, ActiveModel::Type::Boolean.new.cast(value)]
      else
        [key, value]
      end
    end
  end

  # This method collects all checkbox options on the available report types
  def checkbox_options
    @checkbox_options ||= [].tap do |options|
      report_types.each do |report|
        report['options'].each do |option|
          options << option['name'] if option['type'] == 'checkbox'
        end
      end
    end.uniq
  end

  def sanitized_task_options
    task_options.delete_if {|k, _| k.to_s.downcase.include? 'password' }
  end

  def courses
    @courses ||= [].tap do |array|
                   Xikolo.paginate(
                     course_api.rel(:courses).get(alphabetic: true, public: true, groups: 'any')
                   ) {|course| array << course }
                 end.map do |course|
      ["#{course['course_code']} - #{course['title'].truncate(40)}", course['id']]
    end
  end

  def classifiers
    @classifiers ||= Course::Classifier.where(cluster_id: %w[category reporting topic]).map do |classifier|
      ["#{classifier.cluster_id} - #{classifier.title.truncate(40)}", classifier.id]
    end
  end

  def course_api
    @course_api ||= Xikolo.api(:course).value!
  end

  def lanalytics_api
    @lanalytics_api ||= Xikolo.api(:learnanalytics).value!
  end
end

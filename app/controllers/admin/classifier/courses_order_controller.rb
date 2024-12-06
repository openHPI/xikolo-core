# frozen_string_literal: true

class Admin::Classifier::CoursesOrderController < Abstract::FrontendController
  require_permission 'course.cluster.manage'

  def index
    @classifier = Admin::Classifier::CoursesOrderPresenter.new(Course::Classifier.find(params[:classifier_id]))

    render template: 'admin/classifiers/courses_order'
  end

  def update
    @classifier = Course::Classifier.find(params[:classifier_id])

    if params[:courses].blank?
      # Destroy existing course assignments if all are removed.
      @classifier.classifier_assignments.delete_all
    else
      begin
        @classifier.transaction do
          # 1. Destroy all course assignments.
          # Destroying all resources is a workaround, since acts as list cannot
          # handle partial updates on join tables.
          @classifier.classifier_assignments.delete_all

          # 2. Create course assignments and thus update positions accordingly.
          course_ids = Course::Course.not_deleted.where(id: params[:courses]).pluck(:id)
          params[:courses].select do |id|
            course_ids.include? id
          end.each.with_index(1) do |course_id, index|
            @classifier.classifier_assignments.create!(course_id:, position: index)
          end
        end
      rescue ActiveRecord::RecordInvalid, ActiveRecord::StatementInvalid
        add_flash_message :error, t(:'flash.error.courses_order_failed')
        return redirect_to admin_cluster_classifier_courses_order_path(@classifier.cluster, @classifier)
      end
    end

    add_flash_message :success, t(:'flash.success.courses_order_updated')
    redirect_to admin_cluster_classifier_courses_order_path(@classifier.cluster, @classifier)
  end
end

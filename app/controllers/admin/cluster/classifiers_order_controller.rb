# frozen_string_literal: true

class Admin::Cluster::ClassifiersOrderController < Abstract::FrontendController
  require_permission 'course.cluster.manage'

  def index
    @cluster = Admin::ClusterPresenter.new(Course::Cluster.find(params[:cluster_id]))

    render template: 'admin/classifiers/order'
  end

  def update
    cluster = Course::Cluster.find(params[:cluster_id])
    if params[:classifiers].present?
      begin
        cluster.transaction do
          cluster.classifiers.each do |classifier|
            classifier.set_list_position(params[:classifiers].index(classifier.id) + 1, true)
          end

          cluster.update!(sort_mode: 'manual')
        end

        add_flash_message(:success, t(:'flash.success.classifiers_order_updated'))
        redirect_to admin_cluster_url(cluster), status: :see_other
      rescue ActiveRecord::RecordInvalid
        add_flash_message(:error, t(:'flash.error.classifiers_order_failed'))
        redirect_to admin_cluster_classifiers_order_url(cluster), status: :see_other
      end
    else
      add_flash_message(:error, t(:'flash.error.classifiers_order_failed'))
      redirect_to admin_cluster_classifiers_order_url(cluster), status: :see_other
    end
  end
end

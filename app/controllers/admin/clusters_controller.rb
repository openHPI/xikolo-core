# frozen_string_literal: true

class Admin::ClustersController < Admin::BaseController
  def index
    authorize! 'course.cluster.index'
    @clusters = CourseService::Cluster.all
  end

  def show
    authorize! 'course.cluster.index'
    @cluster = Admin::ClusterPresenter.new(
      CourseService::Cluster.find(params[:id])
    )
  end

  def edit
    authorize! 'course.cluster.manage'
    @cluster = CourseService::Cluster.find(params[:id])
  end

  def update
    authorize! 'course.cluster.manage'
    @cluster = CourseService::Cluster.find(params[:id])
    if @cluster.update(cluster_params)
      add_flash_message :success, t(:'flash.success.cluster_updated')
      redirect_to admin_clusters_path, status: :see_other
    else
      add_flash_message :error, t(:'flash.error.cluster_not_updated')
      render :edit, status: :unprocessable_content
    end
  end

  private

  def cluster_params
    params.require(:course_cluster).permit(:visible, translations: {})
  end
end

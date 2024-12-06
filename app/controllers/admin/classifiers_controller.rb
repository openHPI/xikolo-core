# frozen_string_literal: true

class Admin::ClassifiersController < Admin::BaseController
  require_permission 'course.cluster.manage'

  def new
    @cluster = Course::Cluster.find(params[:cluster_id])
    @classifier = Course::Classifier.new
  end

  def edit
    @classifier = Course::Classifier.find(params[:id])
    @cluster = @classifier.cluster
  end

  def create
    @cluster = Course::Cluster.find(params[:cluster_id])
    @classifier = @cluster.classifiers.build(create_params)
    if @classifier.save
      add_flash_message :success, t(:'flash.success.classifier_created')
      redirect_to admin_cluster_path(@cluster)
    else
      add_flash_message :error, t(:'flash.error.classifier_not_created')
      render(action: :new)
    end
  end

  def update
    @classifier = Course::Classifier.find(params[:id])
    if @classifier.update(update_params)
      add_flash_message :success, t(:'flash.success.classifier_updated')
      redirect_to admin_cluster_path(@classifier.cluster)
    else
      # Set the cluster to re-render the form properly.
      @cluster = @classifier.cluster
      add_flash_message :error, t(:'flash.error.classifier_not_updated')
      render(action: :edit)
    end
  end

  def destroy
    classifier = Course::Classifier.find(params[:id])
    if classifier.destroy
      add_flash_message :success, t(:'flash.success.classifier_deleted')
    else
      add_flash_message :error, t(:'flash.error.classifier_not_deleted')
    end

    redirect_to admin_cluster_path(classifier.cluster)
  end

  private

  def create_params
    params.require(:classifier).permit(:title, translations: {}, descriptions: {})
  end

  def update_params
    params.require(:classifier).permit(translations: {}, descriptions: {})
  end
end

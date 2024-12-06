# frozen_string_literal: true

class Admin::ClusterPresenter
  extend Forwardable

  def_delegators :@cluster, :id, :title, :translations, :classifiers

  def initialize(cluster)
    @cluster = cluster
  end

  def sort_mode_i18n
    I18n.t("admin.classifiers.sort_mode.#{@cluster.sort_mode}")
  end

  def classifiers_order_select
    @cluster.classifiers.map {|tag| [tag.localized_title, tag.id] }
  end

  def to_param
    id
  end
end

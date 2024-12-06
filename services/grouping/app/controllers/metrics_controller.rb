# frozen_string_literal: true

class MetricsController < ApplicationController
  responders Responders::DecorateResponder,
    Responders::HttpCacheResponder,
    Responders::PaginateResponder

  respond_to :json

  def index
    metrics = if params[:user_test_id].present?
                UserTest.find(params[:user_test_id]).metrics
              elsif params[:available].present?
                MetricDecorator.decorate_collection(
                  Metrics::Metric.available_metrics.map(&:new)
                )
              else
                Metrics::Metric.all
              end
    respond_with metrics
  end

  def show
    respond_with Metrics::Metric.find(params[:id])
  end
end

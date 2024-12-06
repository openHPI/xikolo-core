# frozen_string_literal: true

module Course
  module Ajax
    class TopicsController < Abstract::AjaxController
      respond_to :json

      before_action :ensure_logged_in

      def create
        authorize! 'course.content.access.available'

        topic = ::Pinboard::TopicForm.from_params(topic_params)

        unless topic.valid?
          return render status: :unprocessable_entity,
            json: {errors: topic.errors}
        end

        result = Xikolo.api(:pinboard).value!.rel(:topics).post(
          topic.to_resource.merge(
            author_id: current_user.id,
            course_id: the_course.id,
            item_id: UUID4(params[:item_id])
          )
        ).value!

        topic = VideoItemTopicPresenter.new(result, the_course.course_code)

        render status: :ok, json: {
          title: topic.title,
          abstract: topic.abstract,
          timestamp: topic.formatted_timestamp,
          url: topic.url,
        }
      rescue Restify::NetworkError, Restify::ResponseError
        topic.errors.add(:base, I18n.t(:'errors.messages.topic.base.not_created'))
        render status: :unprocessable_entity,
          json: {errors: topic.errors}
      end

      private

      def topic_params
        params.require(:topic).permit(:title, :text, :video_timestamp).to_h
      end

      def auth_context
        the_course.context_id
      end

      def request_course
        Xikolo::Course::Course.find params[:course_id]
      end
    end
  end
end

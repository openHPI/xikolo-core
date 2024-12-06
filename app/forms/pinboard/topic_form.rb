# frozen_string_literal: true

class Pinboard::TopicForm < XUI::Form
  self.form_name = 'topic'

  attribute :title, :single_line_string
  attribute :text, :markup
  attribute :video_timestamp, :single_line_string

  validates :title, :text, presence: true

  class FirstPostAndMetaData
    def to_resource(resource, _obj)
      resource['first_post'] = {'text' => resource.delete('text')}
      resource['meta'] = {'video_timestamp' => resource.delete('video_timestamp')}
      resource
    end
  end

  process_with { FirstPostAndMetaData.new }
end

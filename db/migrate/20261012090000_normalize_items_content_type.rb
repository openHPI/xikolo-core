# frozen_string_literal: true

class NormalizeItemsContentType < ActiveRecord::Migration[8.1]
  LEGACY_TYPES = {
    'video' => 'Video::Video',
    'lti_exercise' => 'Lti::Exercise',
    'rich_text' => 'CourseService::Richtext',
    'richtext' => 'CourseService::Richtext',
    'cmi5' => 'Cmi5::Item',
    'quiz' => 'QuizService::Quiz',
  }.freeze

  def up
    update_types(LEGACY_TYPES)
  end

  def down
    update_types(LEGACY_TYPES.except('richtext').invert)
  end

  private

  def update_types(types)
    types.each do |old_type, new_type|
      safety_assured do
        execute <<~SQL.squish
          UPDATE items SET content_type = #{quote(new_type)} WHERE content_type = #{quote(old_type)}
        SQL
      end
    end
  end
end

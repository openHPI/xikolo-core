# frozen_string_literal: true

class PeerAssessment::NoteForm
  include ActiveModel::Model
  include ActiveModel::Serializers::JSON

  attr_accessor :text, :subject_id, :subject_type

  validates :text, presence: true

  def attributes
    {'text' => nil, 'subject_id' => nil, 'subject_type' => 'Conflict'}
  end
end

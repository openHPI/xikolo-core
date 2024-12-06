# frozen_string_literal: true

module Collabspace
  class CollabspacesForm
    include ActiveModel::Model
    include ActiveModel::Serializers::JSON

    attr_accessor :id, :name, :is_open, :course_id, :owner_id, :kind, :description, :details

    validates :name, presence: true
    validates :description, length: {maximum: 400}

    def initialize(collab_space = nil)
      if collab_space
        self.id = collab_space[:id]
        self.course_id = collab_space[:course_id]
        self.owner_id = collab_space[:owner_id]
        self.name = collab_space[:name]
        self.kind = collab_space[:kind]
        self.description = collab_space[:description]
        self.details = collab_space[:details]
        if collab_space[:kind] == 'team'
          self.is_open = false
        else
          self.is_open = collab_space[:is_open]
        end
      end
    end

    def save
      return false unless valid?

      if persisted?
        Xikolo.api(:collabspace).value!.rel(:collab_space).patch(as_json, id:).value!
      else
        collabspace = Xikolo.api(:collabspace).value!.rel(:collab_space).post(as_json).value!
        self.id = collabspace['id']
      end

      true
    end

    def persisted?
      id
    end

    def team?
      kind == 'team'
    end

    def attributes
      {
        'name' => nil,
        'is_open' => false,
        'course_id' => nil,
        'owner_id' => nil,
        'kind' => 'group',
        'description' => nil,
        'details' => nil,
      }
    end
  end
end

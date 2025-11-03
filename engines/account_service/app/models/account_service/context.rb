# frozen_string_literal: true

module AccountService
class Context < ApplicationRecord # rubocop:disable Layout/IndentationWidth
  self.table_name = :contexts

  belongs_to :parent, class_name: 'AccountService::Context', optional: true, inverse_of: false

  validates :parent_id, presence: {message: 'required'}

  class << self
    def resolve(param)
      if param.to_s == 'root'
        root
      elsif param.is_a?(self)
        param
      else
        find param.to_s
      end
    end

    def non_root
      where.not parent_id: nil
    end

    def root
      root = find_or_initialize_by parent_id: nil
      root.save validate: false if root.new_record?
      root
    end

    def root_id
      root.id.freeze
    end

    def ascent(context)
      resolve(context).ascent.to_a
    end
  end

  def ancestors(&block)
    if block
      if parent
        yield parent
        parent.ancestors(&block)
      end
    else
      to_enum :ancestors
    end
  end

  def ascent(&block)
    if block
      yield self
      parent&.ascent(&block)
    else
      to_enum :ascent
    end
  end
end
end

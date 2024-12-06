# frozen_string_literal: true

module ItemStats
  class UnknownItemStats < BaseStats
    def render(ctx)
      ctx.render('course/admin/item_stats/unknown')
    end
  end
end

# frozen_string_literal: true

module Voucher
  class Stats
    GroupedStats = Struct.new(:issued, :claimed) do
      def percentage
        (claimed.to_f / issued * 100).round(2)
      end
    end

    def global
      @global ||= GroupedStats.new(
        ::Voucher::Voucher.count,
        ::Voucher::Voucher.claimed.count
      )
    end

    def by_product
      @by_product ||= grouped(
        ::Voucher::Voucher.group(:product_type).order(:product_type),
        transform_keys: lambda do |types|
          types.to_h {|type| [type, type] }
        end
      )
    end

    def by_tag
      @by_tag ||= grouped(
        ::Voucher::Voucher.group(:tag).order(:tag),
        transform_keys: lambda do |tags|
          tags.to_h {|tag| [tag, tag] }
        end
      )
    end

    def by_course
      @by_course ||= grouped(
        ::Voucher::Voucher
          .where.not(course_id: nil)
          .joins(:course)
          .group(:course_id)
          .order('count_all DESC'),
        transform_keys: lambda do |ids|
          ::Course::Course.find(ids).pluck(:id, :course_code).to_h
        end
      )
    end

    private

    def grouped(scope, transform_keys:)
      issued = scope.count
      claimed = scope.claimed.count

      mapped_keys = transform_keys.call(issued.keys)

      issued.to_h do |grouping_key, issued_count|
        new_key = mapped_keys[grouping_key]
        new_value = GroupedStats.new(issued_count, claimed[grouping_key].to_i)

        [new_key, new_value]
      end
    end
  end
end

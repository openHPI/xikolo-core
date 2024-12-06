# frozen_string_literal: true

module Account
  class Treatment < ::ApplicationRecord
    has_many :consents, class_name: 'Account::Consent', dependent: :destroy

    class << self
      def lookup!(id: nil, name: nil)
        scope = self
        scope = scope.where(id:) if id.present?
        scope = scope.where(name:) if name.present?
        scope.take!
      end
    end

    def group
      @group ||= Account::Group.find_by(name: "treatment.#{name}")
    end
  end
end

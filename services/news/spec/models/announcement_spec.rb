# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Announcement, type: :model do
  subject(:announcement) { create(:announcement) }

  describe '(validations)' do
    context 'author_id' do
      it { is_expected.to accept_values_for(:author_id, SecureRandom.uuid) }
      it { is_expected.not_to accept_values_for(:author_id, nil) }
    end
  end
end

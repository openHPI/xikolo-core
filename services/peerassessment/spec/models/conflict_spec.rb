# frozen_string_literal: true

require 'spec_helper'

describe Conflict, type: :model do
  subject(:conflict) { create(:conflict) }

  it { expect(conflict).not_to accept_values_for(:conflict_subject_type, 'Random') }

  it do
    expect(conflict).to accept_values_for \
      :conflict_subject_type,
      'Review',
      'Submission',
      nil
  end
end

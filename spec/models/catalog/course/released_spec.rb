# frozen_string_literal: true

require 'spec_helper'

describe Catalog::Course, '.released', type: :model do
  subject(:scope) { described_class.released }

  before do
    create(:course, :preparing, title: 'A course in preparation')
    create(:course, :upcoming, title: 'An upcoming course')
    create(:course, :active, title: 'An active course')
    create(:course, :archived, title: 'An archived course')
    create(:course, :self_paced, title: 'A self-paced course')
  end

  it 'includes all published courses, i.e. moved out of "preparation" state' do
    expect(scope).to contain_exactly(
      an_object_having_attributes(title: 'An upcoming course'),
      an_object_having_attributes(title: 'An active course'),
      an_object_having_attributes(title: 'An archived course'),
      an_object_having_attributes(title: 'A self-paced course')
    )
  end
end

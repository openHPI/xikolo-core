# frozen_string_literal: true

require 'spec_helper'

describe CalendarEvent, type: :model do
  subject { event }

  let(:event) { create(:calendar_event) }

  it { is_expected.not_to accept_values_for(:title, '', nil) }
  it { is_expected.to accept_values_for(:title, 'Event', 'New Event') }
  it { is_expected.not_to accept_values_for(:user_id, '', nil) }
  it { is_expected.to accept_values_for(:user_id, event.user_id) }
  it { is_expected.not_to accept_values_for(:start_time, '', nil) }
  it { is_expected.to accept_values_for(:start_time, event.start_time) }
  it { is_expected.not_to accept_values_for(:end_time, '', nil) }
  it { is_expected.to accept_values_for(:end_time, event.end_time) }
  it { is_expected.not_to accept_values_for(:category, '', nil, '  ', 'new_category') }
  it { is_expected.to accept_values_for(:category, 'available', 'unavailable', 'meeting', 'milestone', 'other') }
end

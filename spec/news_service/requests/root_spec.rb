# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Root', type: :request do
  subject { restify_with_headers(news_service_url).get.value! }

  it { is_expected.to have_rel :announcements }
  it { is_expected.to have_rel :announcement }
  it { is_expected.to have_rel :visits }

  it { is_expected.to have_rel :system_info }

  # DEPRECATED RELATIONS
  it { is_expected.to have_rel :news_index }
  it { is_expected.to have_rel :news }
end

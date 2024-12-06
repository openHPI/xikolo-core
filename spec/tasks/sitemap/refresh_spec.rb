# frozen_string_literal: true

require 'spec_helper'
require 'rake'

describe 'sitemap:refresh', skip: ENV['TEAMCITY_VERSION'].present? do
  subject(:refresh_sitemap) do
    Rake.application.invoke_task 'sitemap:refresh'
  end

  after do
    Rake::Task['sitemap:refresh'].reenable
    Rake::Task['sitemap:create'].reenable
    Rake::Task['sitemap:upload_to_s3'].reenable
  end

  let(:course) { build(:'course:course') }
  let!(:store_sitemap) do
    stub_request(:put, 'https://s3.xikolo.de/xikolo-public/sitemaps/sitemap.xml.gz')
      .to_return(status: 200)
  end
  let!(:ping_google) do
    stub_request(:get, 'http://www.google.com/webmasters/tools/ping?sitemap=https://xikolo.de/sitemap.xml.gz')
      .to_return(status: 200)
  end
  let!(:ping_bing) do
    stub_request(:get, 'http://www.bing.com/ping?sitemap=https://xikolo.de/sitemap.xml.gz')
      .to_return(status: 200)
  end

  before(:all) { Rails.application.load_tasks if Rake::Task.tasks.empty? } # rubocop:disable RSpec/BeforeAfterAll

  before do
    Stub.service(:course, build(:'course:root'))
    Stub.request(:course, :get, '/courses', query: {hidden: false, public: true})
      .to_return Stub.json([course])
    Stub.request(:course, :get, '/items', query: {course_id: course['id'], open_mode: true})
      .to_return Stub.json([])
  end

  it 'uploads the sitemap to S3' do
    refresh_sitemap
    expect(store_sitemap).to have_been_requested
  end

  it 'pings the search engines' do
    refresh_sitemap
    expect(ping_google).to have_been_requested
    expect(ping_bing).to have_been_requested
  end

  context 'without abstract' do
    let(:course_params) { super().merge(abstract: nil) }

    it 'creates the sitemap without errors' do
      refresh_sitemap
      expect(store_sitemap).to have_been_requested
    end
  end
end

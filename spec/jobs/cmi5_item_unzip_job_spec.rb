# frozen_string_literal: true

require 'spec_helper'
require 'fileutils'

RSpec.describe Cmi5ItemUnzipJob, type: :job do
  let(:cmi5_item) { create(:cmi5_item) }

  it 'extracts the package' do
    Cmi5ItemUnzipJob.perform_now(cmi5_item)

    paths = cmi5_item.files.reload.map(&:file_path)

    expect(paths).to include(
      'story.html',
      'story_content/thumbnail.jpg',
      'story_content/triggers.js',
      'html5/data/js/data.js',
      'html5/lib/stylesheets/desktop.min.css'
    )

    files_content_types = cmi5_item.files.reload.map {|x| x.file.content_type }

    expect(files_content_types).to include(
      'text/css',
      'image/jpeg',
      'application/javascript',
      'text/html'
    )
  end

  it 'detects application/javascript for chunked JS containg mixed content like SVGs' do
    Cmi5ItemUnzipJob.perform_now(cmi5_item)

    chunked_js_files = cmi5_item.files.where("file_path LIKE 'story_content/%.js'")

    expect(chunked_js_files).to be_many

    chunked_js_files.each do |file|
      expect(file.file.blob.content_type).to eq('application/javascript')
    end
  end

  it 'enqueues the analysis of the extracted package' do
    expect { Cmi5ItemUnzipJob.perform_now(cmi5_item) }
      .to have_enqueued_job(Cmi5ItemAnalyzeJob).with(cmi5_item)
  end

  it 'removes files from a previous extraction when the package is replaced' do
    Cmi5ItemUnzipJob.perform_now(cmi5_item)

    old_file_ids = cmi5_item.files.reload.pluck(:id)
    expect(old_file_ids).not_to be_empty

    cmi5_item.package.attach(
      io: Rails.root.join('spec/fixtures/files/dummy_cmi5_exercise.zip').open,
      filename: 'dummy_cmi5_exercise.zip'
    )

    Cmi5ItemUnzipJob.perform_now(cmi5_item)

    expect(Cmi5::File.where(id: old_file_ids)).to be_none
    paths = cmi5_item.files.reload.map(&:file_path)
    expect(paths).to include(a_string_ending_with('story.html'))
    expect(cmi5_item.package.blob.content_type).to eq('application/zip')
  end
end

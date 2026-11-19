# frozen_string_literal: true

require 'spec_helper'

describe Form::FileUpload, type: :component do
  subject(:component) { described_class.new(form, :video, **options) }

  let(:form) { ActionView::Helpers::FormBuilder.new(:short, nil, vc_test_controller.view_context, {}) }
  let(:options) { {} }

  it 'renders a file input wired up to the drop zone' do
    render_inline(component)

    expect(page).to have_css('[data-controller="file-upload"]')
    expect(page).to have_css(
      'input[type="file"][name="short[video]"][data-file-upload-target="input"]',
      visible: :all
    )
    expect(page).to have_css('[data-action*="file-upload#drop"]')
  end

  it 'falls back to the generic wording' do
    render_inline(component)

    expect(page).to have_text('Attach file')
    expect(page).to have_text('Drop a file here or pick one from your device.')
    expect(page).to have_text('Select file')
  end

  it 'labels the list of selected files' do
    render_inline(component)

    list_id = page.find('[data-file-upload-target="items"]', visible: :all)['aria-labelledby']

    expect(page).to have_css("##{list_id}", text: 'Selected files', visible: :all)
  end

  context 'with a hint' do
    let(:options) { {hint: 'Drop a video file here.'} }

    it 'describes the input with it' do
      render_inline(component)

      hint_id = page.find('input[type="file"]', visible: :all)['aria-describedby']

      expect(page).to have_css("##{hint_id}", text: 'Drop a video file here.')
    end
  end

  it 'hides the file list until a file is selected' do
    render_inline(component)

    expect(page).to have_css('[data-file-upload-target="list"][hidden]', visible: :all)
    expect(page).to have_no_css('[data-file-upload-target="items"] li', visible: :all)
  end

  it 'passes the upload status texts to the controller' do
    render_inline(component)

    expect(page).to have_css(
      '[data-file-upload-uploading-text-value="Uploading · %{progress}%"]' \
      '[data-file-upload-complete-text-value="Successfully uploaded"]' \
      '[data-file-upload-failed-text-value="Upload failed"]'
    )
  end

  it 'provides an item template with the per-file parts' do
    render_inline(component)

    expect(rendered_content).to include('data-file-upload-target="itemTemplate"')
    %w[name status statusText completeIcon failedIcon bar].each do |part|
      expect(rendered_content).to include(%(data-file-upload-part="#{part}"))
    end
  end

  context 'with a validation error on the attribute' do
    let(:record) do
      CourseService::Short.new.tap { it.errors.add(:video, 'must be a video file') }
    end
    let(:form) do
      ActionView::Helpers::FormBuilder.new(:short, record, vc_test_controller.view_context, {})
    end

    it 'shows the message and marks the input invalid' do
      render_inline(component)

      expect(page).to have_css('p.text-error', text: 'must be a video file')
      expect(page).to have_css('input[type="file"][aria-invalid="true"]', visible: :all)
    end

    it 'describes the input with both the hint and the error' do
      render_inline(component)

      described_by = page.find('input[type="file"]', visible: :all)['aria-describedby'].split

      expect(described_by.size).to eq 2
      described_by.each { expect(page).to have_css("##{it}", visible: :all) }
    end

    it 'marks the drop zone' do
      render_inline(component)

      expect(page).to have_css('[data-action*="file-upload#drop"].border-error')
    end
  end

  context 'with a custom icon and wording' do
    let(:options) do
      {icon: 'video', title: 'Upload video', hint: 'Drop a video file here.', button_label: 'Choose video'}
    end

    it 'uses them instead of the defaults' do
      render_inline(component)

      expect(page).to have_text('Upload video')
      expect(page).to have_text('Drop a video file here.')
      expect(page).to have_css('label.x-btn', text: 'Choose video')
    end
  end

  context 'with additional field options' do
    let(:options) { {accept: 'video/*', multiple: true, direct_upload: true} }

    it 'passes them on to the file field' do
      render_inline(component)

      expect(page).to have_css(
        'input[type="file"][accept="video/*"][multiple][data-direct-upload-url]',
        visible: :all
      )
    end
  end
end

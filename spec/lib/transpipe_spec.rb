# frozen_string_literal: true

require 'spec_helper'

describe Transpipe do
  subject { described_class }

  describe '#enabled?' do
    subject { super().enabled? }

    # Disabled by default
    it { is_expected.to be false }

    context 'w/ TransPipe enabled via configuration' do
      before do
        xi_config <<~YML
          transpipe:
            enabled: true
        YML
      end

      it { is_expected.to be true }
    end
  end

  describe Transpipe::URL do
    describe '#for_course' do
      subject(:url) { described_class.for_course(course) }

      let(:course) { build(:'course:course') }

      before do
        xi_config <<~YML
          transpipe:
            enabled: true
            course_url_template: https://transpipe.example.com/link/platform/courses/{course_id}
        YML
      end

      it 'generates the correct TransPipe URL' do
        expect(url).to eq "https://transpipe.example.com/link/platform/courses/#{course['id']}"
      end
    end

    describe '#for_video' do
      subject(:url) { described_class.for_video(item) }

      let(:course) { build(:'course:course') }
      let(:item) { build(:'course:item', :video, course_id: course['id']) }

      before do
        xi_config <<~YML
          transpipe:
            enabled: true
            course_video_url_template: https://transpipe.example.com/link/platform/courses/{course_id}/videos/{video_id}
        YML
      end

      it 'generates the correct TransPipe URL' do
        expect(url).to eq "https://transpipe.example.com/link/platform/courses/#{course['id']}/videos/#{item['content_id']}"
      end
    end
  end
end

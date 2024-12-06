# frozen_string_literal: true

require 'spec_helper'

describe Course::Richtext, type: :model do
  subject(:richtext) { described_class.create!(params) }

  let(:params) { attributes_for(:richtext, course_id: course.id) }
  let(:course) { create(:course) }

  describe '(deletion)' do
    before do
      richtext
      course
    end

    around {|example| perform_enqueued_jobs(&example) }

    it 'deletes the richtext item' do
      expect { richtext.destroy }.to change(Course::Richtext, :count).from(1).to(0)
    end

    context 'with attached reading material' do
      let(:params) { super().merge text: 's3://xikolo-public/reading_material.pdf' }

      let!(:delete_stub) do
        stub_request(
          :delete,
          'https://s3.xikolo.de/xikolo-public/reading_material.pdf'
        )
      end

      it 'deletes the referenced S3 object' do
        expect { richtext.destroy }.to change(Course::Richtext, :count).from(1).to(0)
        expect(delete_stub).to have_been_requested
      end

      context 'with the same reference in another richtext' do
        before do
          create(:richtext, text: 's3://xikolo-public/reading_material.pdf')
        end

        it 'does not remove the attached file' do
          expect { richtext.destroy }.to change(Course::Richtext, :count).from(2).to(1)
          expect(delete_stub).not_to have_been_requested
        end
      end

      context 'with the same reference in another course description' do
        before do
          create(:course, description: 's3://xikolo-public/reading_material.pdf')
        end

        it 'does not remove the attached file' do
          expect { richtext.destroy }.to change(Course::Richtext, :count).from(1).to(0)
          expect(delete_stub).not_to have_been_requested
        end
      end
    end
  end
end

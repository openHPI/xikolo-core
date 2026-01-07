# frozen_string_literal: true

require 'spec_helper'

describe CourseService::CourseProvider, type: :model do
  let(:course) { create(:'course_service/course', :upcoming, attrs) }
  let(:attrs) { {} }

  describe '#self.sync?' do
    subject(:sync?) { described_class.sync?(course) }

    it 'syncs' do
      expect(sync?).to be_truthy
    end

    context 'with deleted course' do
      let(:attrs) { {deleted: true} }

      it 'syncs' do
        expect(sync?).to be_truthy
      end
    end

    context 'with course in preparation' do
      let(:attrs) { {status: 'preparation'} }

      it 'does not sync' do
        expect(sync?).to be_falsey
      end
    end

    context 'with course changed to preparation' do
      context 'from active' do
        let(:attrs) { {status: 'active'} }

        it 'syncs' do
          course.update status: 'preparation'
          expect(sync?).to be_truthy
        end
      end

      context 'from archive' do
        let(:attrs) { {status: 'archive'} }

        it 'syncs' do
          course.update status: 'preparation'
          expect(sync?).to be_truthy
        end
      end
    end

    context 'with invite only course' do
      let(:attrs) { {invite_only: true} }

      it 'does not sync' do
        expect(sync?).to be_falsey
      end
    end

    context 'with external course' do
      let(:attrs) { {external_course_url: 'https://mooc.house/courses/test2019'} }

      it 'does not sync' do
        expect(sync?).to be_falsey
      end
    end

    context 'with group restricted course' do
      let(:attrs) { {groups: ['partners']} }

      it 'does not sync' do
        expect(sync?).to be_falsey
      end
    end
  end
end

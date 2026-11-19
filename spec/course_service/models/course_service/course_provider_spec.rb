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
      let(:attrs) { {published: false} }

      it 'does not sync' do
        expect(sync?).to be_falsey
      end
    end

    context 'with course changed to published true' do
      context 'from active' do
        let(:attrs) { {published: false} }

        it 'syncs' do
          course.update published: true
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
      let(:attrs) { {external_course_url: 'https://mooc.house/learn/test2019'} }

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

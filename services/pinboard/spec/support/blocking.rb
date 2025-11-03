# frozen_string_literal: true

shared_examples 'a reportable' do |reportable_class|
  let(:params) { {} }
  let(:reportable) { create(reportable_class, params) }

  describe 'blocked?' do
    subject { reportable.blocked? }
    it { is_expected.to be_falsy }

    context 'if blocked' do
      let(:params) { super().merge workflow_state: :blocked }
      it { is_expected.to be_truthy }
    end

    context 'if reviewed' do
      let(:params) { super().merge workflow_state: :reviewed }
      it { is_expected.to be_falsy }
    end
  end

  describe 'auto_blocked?' do
    subject { reportable.auto_blocked? }
    it { is_expected.to be_falsy }

    context 'when reported enough times' do
      before do
        Stub.service(:account, build(:'account:root'))
        Stub.request(
          :account, :get, '/groups/course.the_course.admins'
        ).to_return Stub.json({members_url: '/account_service/groups/course.the_course.admins/members'})
        Stub.request(
          :account, :get, '/groups/course.the_course.admins/members'
        ).to_return Stub.json([
          {id: SecureRandom.uuid},
          {id: SecureRandom.uuid},
        ])

        Stub.service(:course, build(:'course:root'))
        Stub.request(
          :course, :get, "/courses/#{reportable.course_id}"
        ).to_return Stub.json({
          id: reportable.course_id,
          course_code: 'the_course',
        })

        allow(Msgr).to receive(:publish)

        3.times do
          create(:'pinboard_service/abuse_report', reportable:)
        end
      end

      it { is_expected.to be_truthy }

      it 'notifies other services about the auto block' do
        expect(Msgr).to have_received(:publish).twice.with(
          hash_including(key: 'pinboard.blocked_item'),
          to: 'xikolo.notification.notify'
        )
        subject
      end
    end
  end

  describe 'abuse_reports.count' do
    before { create(:'pinboard_service/abuse_report', reportable:) }
    subject { reportable.abuse_reports.count }

    it { is_expected.to eq 1 }
  end
end

shared_examples 'a reviewed reportable' do |reportable_class, update_field|
  describe 'updating the text' do
    let(:reportable) do
      create(reportable_class, workflow_state: :reviewed)
    end
    before { reportable.update! update_field => 'new content' }
    it 'resets the reviewed flag' do
      expect(reportable.reviewed?).to be_falsey
      expect(reportable.new?).to be_truthy
    end
  end
end

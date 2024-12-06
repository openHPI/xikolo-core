# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Teachers: Delete the picture', type: :request do
  subject(:update_teacher) { api.rel(:teacher).patch(update_params, id: teacher.id).value! }

  let(:api) { Restify.new(:test).get.value }
  let(:old_picture_uri) { 's3://xikolo-public/teachers/1/42/tux.jpg' }
  let(:teacher) { create(:teacher, picture_uri: old_picture_uri) }
  let(:old_store_stub_url) { %r{https://s3.xikolo.de/xikolo-public/teachers/[0-9a-zA-Z]+/[0-9a-zA-Z]+/tux.jpg} }
  let(:update_params) { {picture_uri: nil} }

  context 'when the picture_uri is nil' do
    it { is_expected.to respond_with :no_content }

    it 'schedules the removal of the old picture' do
      update_teacher
      expect(FileDeletionWorker.jobs.last['args']).to eq [old_picture_uri]
    end

    it 'updates the picture url to nil' do
      expect { update_teacher }.to change { teacher.reload.picture_url }
        .from(old_store_stub_url).to be_nil
    end
  end
end

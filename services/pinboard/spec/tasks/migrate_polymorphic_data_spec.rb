# frozen_string_literal: true

require 'spec_helper'

Rails.application.load_tasks

RSpec.describe 'migrate_polymorphic_data rake task' do
  describe 'migrate_polymorphic_data for comments' do
    let!(:comment_on_question) { create(:'pinboard_service/comment') }
    let!(:comment_on_answer) { create(:'pinboard_service/comment', :for_answer) }

    describe ':up' do
      it 'adds prefixes for PinboardService' do
        Rake::Task['migrate_polymorphic_data:down'].reenable
        Rake::Task['migrate_polymorphic_data:down'].invoke

        expect do
          Rake::Task['migrate_polymorphic_data:up'].reenable
          Rake::Task['migrate_polymorphic_data:up'].invoke
        end.to change { comment_on_question.reload.commentable_type }.to('PinboardService::Question')
          .and change { comment_on_answer.reload.commentable_type }.to('PinboardService::Answer')
      end
    end

    describe ':down' do
      it 'removes all prefixes' do
        expect do
          Rake::Task['migrate_polymorphic_data:down'].reenable
          Rake::Task['migrate_polymorphic_data:down'].invoke
        end.to change { comment_on_question.reload.commentable_type }.to('Question')
          .and change { comment_on_answer.reload.commentable_type }.to('Answer')
      end
    end
  end

  describe 'migrate_polymorphic_data for tags' do
    let!(:implicit_tag) { create(:'pinboard_service/implicit_tag') }
    let!(:explicit_tag) { create(:'pinboard_service/explicit_tag') }

    describe ':up' do
      it 'adds prefixes for PinboardService' do
        Rake::Task['migrate_polymorphic_data:down'].reenable
        Rake::Task['migrate_polymorphic_data:down'].invoke

        expect do
          Rake::Task['migrate_polymorphic_data:up'].reenable
          Rake::Task['migrate_polymorphic_data:up'].invoke
        end.to change { implicit_tag.reload.type }.to('PinboardService::ImplicitTag')
          .and change { explicit_tag.reload.type }.to('PinboardService::ExplicitTag')
      end
    end

    describe ':down' do
      it 'removes all prefixes' do
        expect do
          Rake::Task['migrate_polymorphic_data:down'].reenable
          Rake::Task['migrate_polymorphic_data:down'].invoke
        end.to change { implicit_tag.reload.type }.to('ImplicitTag')
          .and change { explicit_tag.reload.type }.to('ExplicitTag')
      end
    end
  end
end

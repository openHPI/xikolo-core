# frozen_string_literal: true

require 'spec_helper'

describe Home::CoursesController, type: :controller do
  describe '#index' do
    subject(:index) { get :index }

    it 'responds with 404 Not Found when the course list is not enabled' do
      expect { index }.to raise_error AbstractController::ActionNotFound
    end

    context 'with enabled course list' do
      before do
        stub_user features: {'course_list' => 'true'}
      end

      it 'answers with a page' do
        expect(index.status).to eq 200
      end
    end
  end
end

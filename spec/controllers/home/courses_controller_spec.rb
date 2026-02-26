# frozen_string_literal: true

require 'spec_helper'

describe Home::CoursesController, type: :controller do
  describe '#index' do
    subject(:index) { get :index }

    it 'answers with a page' do
      expect(index.status).to eq 200
    end
  end
end

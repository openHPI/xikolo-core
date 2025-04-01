# frozen_string_literal: true

require 'spec_helper'

describe 'Teacher: Update', type: :request do
  subject(:update_action) { api.rel(:teacher).patch(data, params: {id: teacher.id}).value! }

  let(:api) { Restify.new(:test).get.value }
  let(:teacher) { create(:teacher) }

  context 'change name' do
    let(:data) { {'name' => 'Hans Otto'} }

    it 'updates the database' do
      expect { update_action }.to change { teacher.reload.name }.from(teacher.name).to('Hans Otto')
    end
  end

  context 'change user_id' do
    let!(:teacher) { create(:teacher, :connected_to_user) }

    context 'user_id not given' do
      let(:data) { {} }

      it 'does not change the user_id' do
        expect { update_action }.not_to change { teacher.reload.user_id }
      end
    end

    context 'user_id given' do
      let(:data) { {'user_id' => generate(:user_id)} }

      it 'does not change the user_id' do
        expect { update_action }.not_to change { teacher.reload.user_id }
      end
    end
  end

  context 'change description' do
    let(:description) { {'en' => 'asdf', 'de' => 'Deutsch!'} }
    let(:data) { {'description' => description} }

    it 'updates the database' do
      expect(teacher.description.keys).to match_array %w[en de]
      expect { update_action }.to change { teacher.reload.description }.from(teacher.description).to(description)
    end

    context 'add new language' do
      let(:description) { {'en' => 'asdf', 'de' => 'Deutsch!', 'dk' => 'Tak!'} }

      it 'updates the database' do
        expect(teacher.description.keys).to match_array %w[en de]
        expect { update_action }.to change { teacher.reload.description }.from(teacher.description).to(description)
      end
    end

    context 'delete a language' do
      let(:description) { {'en' => 'asdf'} }

      it 'updates the database' do
        expect(teacher.description.keys).to match_array %w[en de]
        expect { update_action }.to change { teacher.reload.description }.from(teacher.description).to(description)
      end
    end
  end
end

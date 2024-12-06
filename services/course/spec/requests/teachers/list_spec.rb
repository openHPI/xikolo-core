# frozen_string_literal: true

require 'spec_helper'

describe 'Teachers: List', type: :request do
  subject(:result) { api.rel(:teachers).get.value }

  let(:api) { Restify.new(:test).get.value }
  let(:teacher) { create(:teacher) }

  it 'responds with 200 Ok' do
    expect(result.response.status).to eq :ok
  end

  it 'responds with groups' do
    teacher
    expect(result).to eq [teacher.decorate.as_json(api_version: 1)]
  end

  context 'filter course_id' do
    subject(:result) { api.rel(:teachers).get(course: course1.id).value }

    let!(:teachers) { create_list(:teacher, 10) }
    let!(:course1) { create(:course, teacher_ids: [teachers[3].id, teachers[1].id, teachers[8].id]) }

    before { create(:course, teacher_ids: [teachers[1].id, teachers[7].id, teachers[3].id]) }

    it 'responds with teachers of this course in order' do
      expect(result).to eq [3, 1, 8].map {|i| teachers[i].decorate.as_json(api_version: 1) }
    end
  end

  context 'filter query' do
    subject(:result) { api.rel(:teachers).get(query: 'ott').value }

    let!(:teacher1) { create(:teacher, name: 'Hans Otto') }
    let!(:teacher2) { create(:teacher, name: 'ottonen') }
    let!(:teacher3) { create(:teacher, name: 'Mit ott') }

    before { create(:teacher, name: 'Aber ganz') }

    it 'responds with teachers of this course in order' do
      expect(result).to match_array [teacher1, teacher2, teacher3].map {|i| i.decorate.as_json(api_version: 1) }
    end
  end

  context 'select user_id' do
    subject { api.rel(:teachers).get(user_id: teacher3.user_id).value! }

    let!(:teacher3) { create(:teacher, :connected_to_user) }

    before do
      create(:teacher)
      create(:teacher, :connected_to_user)
    end

    it { is_expected.to contain_exactly(teacher3.decorate.as_json(api_version: 1)) }
  end

  context 'with sort parameter' do
    subject(:result) { api.rel(:teachers).get(sort: 'name').value }

    let!(:teacher_list) do
      [].tap do |teachers|
        6.times do |n|
          teacher = create(:teacher, name: "Teacher #{('a'..'f').to_a[5 - n]}")
          teachers << teacher
        end
      end
    end

    it 'responds with teachers in order' do
      teacher_list
      expect(result.map(&:to_hash)).to match [
        hash_including('name' => 'Teacher a'),
        hash_including('name' => 'Teacher b'),
        hash_including('name' => 'Teacher c'),
        hash_including('name' => 'Teacher d'),
        hash_including('name' => 'Teacher e'),
        hash_including('name' => 'Teacher f'),
      ]
    end
  end
end

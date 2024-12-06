# frozen_string_literal: true

require 'spec_helper'

# See http://jsonapi.org/format/#fetching-includes
describe 'Including has-many relationships' do
  include Rack::Test::Methods

  def app
    @app ||= Class.new(Xikolo::Endpoint::CollectionEndpoint)
  end

  subject(:response) { get '/123?include=teachers' }

  let(:course) { {'id' => course_id, 'resource_id' => 2, 'name' => 'The course', 'teachers' => teachers} }
  let(:course_id) { 1 }
  let(:teachers) do
    [
      {'id' => 3, 'age' => 43},
      {'id' => 4, 'age' => 44},
      {'id' => 5, 'age' => 45},
    ]
  end

  let(:teachers_endpoint) do
    Class.new(Xikolo::Endpoint::CollectionEndpoint) do
      entity do
        type 'teachers'
        attribute('age') do
          type :integer
        end
      end

      filters do
        required 'course_id'
      end

      collection do
        get 'Load all teachers' do
          if filters['course_id'] == 1
            [{'id' => 7, 'age' => 37}, {'id' => 8, 'age' => 38}, {'id' => 9, 'age' => 39}]
          else
            [{'id' => 15, 'age' => 60}]
          end
        end
      end
    end
  end

  before do
    t = teachers_endpoint
    blk = teachers_relation_blk
    app.entity do
      type 'courses'
      attribute('name') do
        type :string
      end
      includable has_many('teachers', t, &blk)
    end

    c = course
    app.member do
      get 'Retrieve a course' do
        c
      end
    end
  end

  context 'when loading related resource via other endpoint' do
    let(:teachers_relation_blk) do
      proc {
        filter_by 'course_id'
      }
    end

    it 'responds with 200 Ok' do
      expect(response.status).to eq 200
    end

    describe 'JSON body' do
      subject(:json) { JSON.parse(response.body) }

      it 'exposes the relationships' do
        expect(json['data']['relationships']['teachers']['data']).to contain_exactly(
          {'type' => 'teachers', 'id' => 7},
          {'type' => 'teachers', 'id' => 8},
          {'type' => 'teachers', 'id' => 9}
        )
      end

      it 'exposes the relationship URL' do
        expect(
          json['data']['relationships']['teachers']['links']['related']
        ).to eq '/api/v2/teachers?filter%5Bcourse_id%5D=1'
      end

      it 'exposes the related objects' do
        expect(json['included']).to contain_exactly({
          'id' => 7,
            'type' => 'teachers',
            'attributes' => {'age' => 37},
        }, {
          'id' => 8,
            'type' => 'teachers',
            'attributes' => {'age' => 38},
        }, {
          'id' => 9,
            'type' => 'teachers',
            'attributes' => {'age' => 39},
        })
      end
    end
  end

  context 'when loading related resource via other endpoint and non-default identifier key' do
    let(:teachers_relation_blk) do
      proc {
        filter_by 'course_id', 'resource_id'
      }
    end

    it 'responds with 200 Ok' do
      expect(response.status).to eq 200
    end

    describe 'JSON body' do
      subject(:json) { JSON.parse(response.body) }

      it 'exposes the relationships' do
        expect(json['data']['relationships']['teachers']['data']).to contain_exactly({'type' => 'teachers', 'id' => 15})
      end

      it 'exposes the relationship URL' do
        expect(
          json['data']['relationships']['teachers']['links']['related']
        ).to eq '/api/v2/teachers?filter%5Bcourse_id%5D=2'
      end

      it 'exposes the related objects' do
        expect(json['included']).to contain_exactly({
          'id' => 15,
            'type' => 'teachers',
            'attributes' => {'age' => 60},
        })
      end
    end
  end

  context 'when loading related resources from their embedded representation' do
    let(:teachers_relation_blk) do
      proc {
        embedded {|course| course['teachers'] }
      }
    end

    it 'responds with 200 Ok' do
      expect(response.status).to eq 200
    end

    describe 'JSON body' do
      subject(:json) { JSON.parse(response.body) }

      it 'exposes the relationships' do
        expect(json['data']['relationships']['teachers']['data']).to contain_exactly({'type' => 'teachers', 'id' => 3},
          {'type' => 'teachers', 'id' => 4}, {'type' => 'teachers', 'id' => 5})
      end

      it 'exposes the related objects' do
        expect(json['included']).to contain_exactly({
          'id' => 3,
            'type' => 'teachers',
            'attributes' => {'age' => 43},
        }, {
          'id' => 4,
            'type' => 'teachers',
            'attributes' => {'age' => 44},
        }, {
          'id' => 5,
            'type' => 'teachers',
            'attributes' => {'age' => 45},
        })
      end
    end
  end
end

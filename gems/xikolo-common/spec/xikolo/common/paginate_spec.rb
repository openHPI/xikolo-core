# frozen_string_literal: true

RSpec.describe 'Xikolo.paginate' do
  let(:restify_call) { Restify.new('http://demo.de').get }

  let!(:request_page1) do
    WebMock.stub_request(
      :get,
      'http://demo.de'
    ).to_return Stub.json(
      [{id: 1}, {id: 2}],
      links: {
        next: 'http://demo.de/page/2',
      }
    )
  end

  let!(:request_page2) do
    WebMock.stub_request(
      :get,
      'http://demo.de/page/2'
    ).to_return Stub.json(
      [{id: 3}, {id: 4}],
      links: {
        next: 'http://demo.de/page/3',
      }
    )
  end

  let!(:request_page3) do
    WebMock.stub_request(
      :get,
      'http://demo.de/page/3'
    ).to_return Stub.json(
      [{id: 5}]
    )
  end

  describe 'block form' do
    it 'loads all pages' do
      Xikolo.paginate(restify_call) do
        # Do something with each item
      end
      expect(request_page1).to have_been_requested
      expect(request_page2).to have_been_requested
      expect(request_page3).to have_been_requested
    end

    it 'calls the block with each item in the right order' do
      result = []
      Xikolo.paginate(restify_call) do |item|
        result << item.to_hash
      end

      expect(result).to eq [
        {'id' => 1},
        {'id' => 2},
        {'id' => 3},
        {'id' => 4},
        {'id' => 5},
      ]
    end

    it 'also passes the current page to the block' do
      result = []
      Xikolo.paginate(restify_call) do |_item, page|
        result << page.to_ary
      end

      expect(result).to eq [
        [{'id' => 1}, {'id' => 2}],
        [{'id' => 1}, {'id' => 2}],
        [{'id' => 3}, {'id' => 4}],
        [{'id' => 3}, {'id' => 4}],
        [{'id' => 5}],
      ]
    end

    describe 'break' do
      it 'stops the iteration' do
        result = []
        Xikolo.paginate(restify_call) do |item|
          result << item.to_hash
          break
        end

        expect(result).to eq [
          {'id' => 1},
        ]
      end

      it 'stops requesting more pages' do
        Xikolo.paginate(restify_call) do
          break
        end

        expect(request_page1).to have_been_requested
        expect(request_page2).to_not have_been_requested
        expect(request_page3).to_not have_been_requested
      end
    end
  end

  describe 'method usage' do
    describe '#each_page' do
      it 'loads all pages' do
        Xikolo.paginate(restify_call).each_page do
          # Do something with each page
        end
        expect(request_page1).to have_been_requested
        expect(request_page2).to have_been_requested
        expect(request_page3).to have_been_requested
      end

      it 'calls the block with each page' do
        pages = []
        Xikolo.paginate(restify_call).each_page do |page|
          pages << page.to_ary
        end

        expect(pages).to eq [
          [{'id' => 1}, {'id' => 2}],
          [{'id' => 3}, {'id' => 4}],
          [{'id' => 5}],
        ]
      end

      describe 'break' do
        it 'stops the iteration' do
          pages = []
          Xikolo.paginate(restify_call).each_page do |page| # rubocop:disable Lint/UnreachableLoop
            pages << page.to_ary
            break
          end

          expect(pages).to eq [
            [{'id' => 1}, {'id' => 2}],
          ]
        end

        it 'stops requesting more pages' do
          Xikolo.paginate(restify_call).each_page do # rubocop:disable Lint/UnreachableLoop
            break
          end

          expect(request_page1).to have_been_requested
          expect(request_page2).to_not have_been_requested
          expect(request_page3).to_not have_been_requested
        end
      end
    end
  end
end

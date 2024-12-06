# frozen_string_literal: true

RSpec.shared_examples 'a paginated action' do
  describe 'response' do
    let(:per_page) { (records.size / 4) + 1 }
    let(:params) { super().merge per_page: }
    let(:links) do
      response
        .headers['Link']
        .split(',')
        .map do |link|
          if link =~ /<.*\?(.*?)>;\s+rel="(.*?)"/
            [Regexp.last_match[2], Regexp.last_match[1]]
          else
            [$PROGRAM_NAME]
          end
        end
    end

    describe 'Link-Header' do
      subject { links }

      it { should include ['first', "page=1&per_page=#{per_page}"] }
      it { should include ['next', "page=2&per_page=#{per_page}"] }
      it { should include ['last', "page=4&per_page=#{per_page}"] }
    end

    context 'page: 2' do
      let(:params) { super().merge page: 2 }

      describe 'Link-Header' do
        subject { links }

        it { should include ['first', "page=1&per_page=#{per_page}"] }
        it { should include ['prev', "page=1&per_page=#{per_page}"] }
        it { should include ['next', "page=3&per_page=#{per_page}"] }
        it { should include ['last', "page=4&per_page=#{per_page}"] }
      end
    end
  end
end

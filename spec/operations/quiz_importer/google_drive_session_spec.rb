# frozen_string_literal: true

require 'spec_helper'

RSpec.describe QuizImporter::GoogleDriveSession do
  before { described_class.instance_variable_set(:@session, nil) }

  describe '.session' do
    it 'memoizes the built session' do
      s = instance_double(described_class::Session)
      expect(described_class).to receive(:build_session).once.and_return(s)
      expect(described_class.session).to be(s)
      expect(described_class.session).to be(s)
    end
  end

  describe '.build_session' do
    let(:json_key_io) { StringIO.new('{"client_email":"a","private_key":"k"}') }

    before do
      allow(described_class).to receive(:auth_file_path).and_return('/tmp/google_auth.json')
      allow(File).to receive(:open).with('/tmp/google_auth.json', 'r').and_yield(json_key_io)
      allow(Google::Auth::ServiceAccountCredentials).to receive(:make_creds)
        .with(json_key_io: json_key_io, scope: described_class::SCOPES)
        .and_return(instance_double(Google::Auth::ServiceAccountCredentials))
    end

    it 'builds a Session with the derived credentials and scopes' do
      expect(described_class::Session).to receive(:new)
      described_class.build_session
    end
  end

  describe '.auth_file_path' do
    let(:default_path) { Rails.root.join('config', 'google_auth.json').to_s }

    context 'when the file exists and is non-empty' do
      it 'returns the default config path' do
        allow(File).to receive(:exist?).with(default_path).and_return(true)
        allow(File).to receive(:empty?).with(default_path).and_return(false)
        expect(described_class.auth_file_path).to eq(default_path)
      end

      it 'returns a custom path from GOOGLE_AUTH_FILE env var' do
        stub_const('ENV', ENV.to_hash.merge('GOOGLE_AUTH_FILE' => '/custom/google_auth.json'))
        allow(File).to receive(:exist?).with('/custom/google_auth.json').and_return(true)
        allow(File).to receive(:empty?).with('/custom/google_auth.json').and_return(false)
        expect(described_class.auth_file_path).to eq('/custom/google_auth.json')
      end
    end
  end
end

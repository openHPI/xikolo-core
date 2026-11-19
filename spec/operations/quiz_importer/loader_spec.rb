# frozen_string_literal: true

require 'spec_helper'

RSpec.describe QuizImporter::Loader do
  let(:spreadsheet) { 'spreadsheet-title' }
  let(:worksheet) { 'worksheet-title' }
  let(:loader) { described_class.new(spreadsheet: spreadsheet, worksheet: worksheet) }

  describe '#load' do
    it 'returns worksheet rows' do
      session = instance_double(QuizImporter::GoogleDriveSession::Session)
      sheet = instance_double(QuizImporter::GoogleDriveSession::Spreadsheet)
      ws = instance_double(QuizImporter::GoogleDriveSession::Worksheet, rows: [%w[a b], %w[c d]])
      allow(QuizImporter::GoogleDriveSession).to receive(:session).and_return(session)
      allow(session).to receive(:spreadsheet_by_title).with(spreadsheet).and_return(sheet)
      allow(sheet).to receive(:worksheet_by_title).with(worksheet).and_return(ws)
      expect(loader.load).to eq([%w[a b], %w[c d]])
    end

    it 'raises if spreadsheet not found' do
      session = instance_double(QuizImporter::GoogleDriveSession::Session)
      allow(QuizImporter::GoogleDriveSession).to receive(:session).and_return(session)
      allow(session).to receive(:spreadsheet_by_title).with(spreadsheet).and_return(nil)
      expect { loader.load }.to raise_error(QuizImporter::LoadWorksheetError, /Spreadsheet could not be opened/)
    end

    it 'raises if worksheet not found' do
      session = instance_double(QuizImporter::GoogleDriveSession::Session)
      sheet = instance_double(QuizImporter::GoogleDriveSession::Spreadsheet)
      allow(QuizImporter::GoogleDriveSession).to receive(:session).and_return(session)
      allow(session).to receive(:spreadsheet_by_title).with(spreadsheet).and_return(sheet)
      allow(sheet).to receive(:worksheet_by_title).with(worksheet).and_return(nil)
      expect { loader.load }.to raise_error(QuizImporter::LoadWorksheetError, /Worksheet could not be opened/)
    end
  end
end

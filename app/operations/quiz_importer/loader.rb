# frozen_string_literal: true

module QuizImporter
  class Loader
    def initialize(spreadsheet:, worksheet:)
      @spreadsheet = spreadsheet
      @worksheet = worksheet
    end

    def load
      sheet = open_spreadsheet(@spreadsheet)
      open_worksheet(sheet, @worksheet).rows
    end

    private

    attr_reader :spreadsheet, :worksheet

    def open_spreadsheet(title)
      session = GoogleDriveSession.session
      session.spreadsheet_by_title(title) ||
        raise(LoadWorksheetError.new(%(Spreadsheet could not be opened: "#{title}")))
    end

    def open_worksheet(sheet, title)
      sheet.worksheet_by_title(title) ||
        raise(LoadWorksheetError.new(%(Worksheet could not be opened: "#{title}")))
    end
  end
end

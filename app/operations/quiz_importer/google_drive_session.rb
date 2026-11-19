# frozen_string_literal: true

require 'google/apis/drive_v3'
require 'google/apis/sheets_v4'
require 'googleauth'

module QuizImporter
  module GoogleDriveSession
    SCOPES = [
      'https://spreadsheets.google.com/feeds',
      'https://www.googleapis.com/auth/drive',
    ].freeze

    def self.session
      @session ||= build_session
    end

    def self.build_session
      authorization = File.open(auth_file_path, 'r') do |json_key_io|
        Google::Auth::ServiceAccountCredentials.make_creds(
          json_key_io: json_key_io,
          scope: SCOPES
        )
      end
      Session.new(authorization)
    end

    def self.auth_file_path
      ENV.fetch('GOOGLE_AUTH_FILE', Rails.root.join('config', 'google_auth.json').to_s)
    end

    class Session
      def initialize(authorization)
        @authorization = authorization
        @drive = Google::Apis::DriveV3::DriveService.new
        @drive.authorization = authorization
        @sheets = Google::Apis::SheetsV4::SheetsService.new
        @sheets.authorization = authorization
      end

      def spreadsheet_by_title(title)
        escaped_title = title.to_s.gsub("'", "\\\\'")
        response = @drive.list_files(
          q: "mimeType='application/vnd.google-apps.spreadsheet' and trashed=false and name='#{escaped_title}'",
          fields: 'files(id,name)',
          page_size: 1
        )
        file = response.files&.first
        file ? Spreadsheet.new(file.id, @sheets) : nil
      end
    end

    class Spreadsheet
      def initialize(spreadsheet_id, sheets_service)
        @spreadsheet_id = spreadsheet_id
        @sheets_service = sheets_service
      end

      def worksheet_by_title(title)
        spreadsheet = @sheets_service.get_spreadsheet(@spreadsheet_id, fields: 'sheets(properties(title))')
        worksheet = spreadsheet.sheets&.find {|sheet| sheet.properties&.title == title }
        worksheet ? Worksheet.new(@spreadsheet_id, title, @sheets_service) : nil
      end
    end

    class Worksheet
      def initialize(spreadsheet_id, title, sheets_service)
        @spreadsheet_id = spreadsheet_id
        @title = title
        @sheets_service = sheets_service
      end

      def rows
        result = @sheets_service.get_spreadsheet_values(@spreadsheet_id, @title)
        result.values || []
      end
    end
  end
end

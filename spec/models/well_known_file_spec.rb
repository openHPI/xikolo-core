# frozen_string_literal: true

require 'spec_helper'

describe WellKnownFile, type: :model do
  subject(:well_known_file) do
    WellKnownFile.create!(filename: 'security.txt', content: 'X')
  end

  describe 'filename' do
    it 'cannot be blank' do
      expect do
        well_known_file.update!(filename: '')
      end.to raise_error ActiveRecord::RecordInvalid, /Filename can't be blank/
    end

    it 'does not accept slashes' do
      expect do
        well_known_file.update!(filename: 'path/file.txt')
      end.to raise_error ActiveRecord::RecordInvalid, /Filename is invalid/
    end

    it 'does not accept too long values' do
      expect do
        well_known_file.update!(filename: 'A' * 65)
      end.to raise_error ActiveRecord::RecordInvalid, /Filename is too long/
    end
  end

  describe 'content' do
    it 'cannot be blank' do
      expect do
        well_known_file.update!(content: '')
      end.to raise_error ActiveRecord::RecordInvalid, /Content can't be blank/
    end
  end
end

# frozen_string_literal: true

class WellKnownFile < ApplicationRecord
  self.primary_key = :filename

  # The filename can be anything but must not include a slash, as we do not
  # support "nested" files. File extensions are to be included.
  FILENAME_FORMAT = %r{\A[^/]+\z}

  validates :filename, presence: true, format: {with: FILENAME_FORMAT}, length: 0..64
  validates :content, presence: true
end

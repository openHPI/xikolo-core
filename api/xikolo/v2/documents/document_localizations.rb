# frozen_string_literal: true

module Xikolo
  module V2::Documents
    class DocumentLocalizations < Xikolo::Endpoint::CollectionEndpoint
      entity do
        type 'document-localizations'

        attribute('title') {
          description 'The title of the document localization'
          type :string
        }

        attribute('description') {
          description 'The description of the document localization'
          type :string
        }

        attribute('language') {
          description 'The language of the document localization'
          type :string
        }

        attribute('revision') {
          description 'The revision number of the document localization'
          type :integer
        }

        attribute('file_url') {
          description 'The url to the localization file'
          type :string
        }

        has_one('document', Xikolo::V2::Documents::Documents) {
          foreign_key 'document_id'
        }
      end

      filters do
        optional('document') {
          description 'Only return document_localizations belonging to this document'
          alias_for 'document_id'
        }
      end

      collection do
        get 'List all document localizations' do
          Xikolo.api(:course).value!.rel(:document_localizations).get(filters).value!
        end
      end

      member do
        get 'Retrieve information about a document localization' do
          Xikolo.api(:course).value!.rel(:document_localization).get({id: UUID(id).to_s}).value!
        end
      end
    end
  end
end

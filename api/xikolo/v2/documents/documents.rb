# frozen_string_literal: true

module Xikolo
  module V2::Documents
    class Documents < Xikolo::Endpoint::CollectionEndpoint
      entity do
        type 'documents'

        attribute('title') {
          description 'The title of the document'
          type :string
        }

        attribute('description') {
          description 'A short description of the document contents'
          type :string
        }

        attribute('tags') {
          description 'A lists of tags ot the document'
          type :array, of: :string
        }

        attribute('public') {
          description 'flag indication whether a document is available on the platform'
          type :boolean
        }

        includable has_many('localizations', Xikolo::V2::Documents::DocumentLocalizations) {
          filter_by 'document'
        }

        includable has_many('courses', Xikolo::V2::Courses::Courses) {
          filter_by 'document'
        }
      end

      filters do
        optional('course') {
          description 'Only return documents belonging to the course with this UUID'
          alias_for 'course_id'
        }

        optional('tag') {
          description 'Only return documents that are tagged with this tag'
        }

        optional('language') {
          description 'Only return documents that are available in this language'
        }
      end

      paginate!

      collection do
        get 'List all documents' do
          authenticate!
          Xikolo.api(:course).value!.rel(:documents).get(filters).value!
        end
      end

      member do
        get 'Retrieve information about a document' do
          authenticate!
          Xikolo.api(:course).value!.rel(:document).get(id: UUID(id).to_s).value!
        end
      end
    end
  end
end

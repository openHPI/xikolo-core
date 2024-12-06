# frozen_string_literal: true

module Lti
  class Exercise
    class Store < ApplicationOperation
      def initialize(exercise, params)
        super()

        @exercise = exercise
        @params = params
      end

      def call
        if @params[:instructions]
          instructions = @params.delete(:instructions)
          @exercise.assign_attributes @params
          configure_processor! instructions
          process_instructions_and_save
        else
          @exercise.update @params
        end
        @exercise
      end

      private

      def configure_processor!(input)
        @processor = Xikolo::S3::TextWithUploadsProcessor.new \
          bucket: :lti,
          purpose: 'lti_exercise_instructions',
          current: @exercise.instructions,
          text: input,
          valid_refs: @exercise.instructions&.file_refs || []
        @processor.on_new do |upload|
          eid = UUID4(@exercise.id).to_s(format: :base62)
          {
            key: "ltiexercises/#{eid}/#{File.basename upload.key}",
            acl: 'public-read',
            cache_control: 'public, max-age=7776000',
            content_disposition: 'inline',
            content_type: upload.content_type,
          }
        end
      end

      def process_instructions_and_save
        @processor.parse!
        @exercise.instructions = @processor.result
        if @processor.valid? && @exercise.save
          @processor.commit!
          # keep old files due to publicly available text?
          @processor.obsolete_uris.each do |uri|
            # The instructions have been saved, so obsolete S3 files can be removed now.
            # Fault-tolerance: Wait one minute to allow pages for users with slow
            # connection to finish loading.
            S3FileDeletionJob.set(wait: 1.minute).perform_later(uri)
          end
          true
        else
          @processor.rollback!
          @processor.errors.each do |_url, code, _message|
            @exercise.errors.add :instructions, code
          end
          false
        end
      end
    end
  end
end

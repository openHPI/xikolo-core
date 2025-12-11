# frozen_string_literal: true

module Bridges
  module MoocHub
    module Serializers
      ##
      # Responsible for transforming data into the desired format for the given version.
      #
      class CourseSerializerV3
        include MarkdownHelper

        def initialize(context:)
          @config = context.config
          @api = context.api
          @context = context.context
        end

        def serialize(courses)
          @course_visuals = load_visuals!(courses)

          courses.map { serialize_resource(it) }
        end

        private

        def load_visuals!(courses)
          Course::Visual.where(course_id: courses.pluck('id')).index_by(&:course_id)
        end

        def serialize_resource(course)
          {
            id: course['id'],
            type: 'Course',
            attributes: {
              name: course['title'],
              courseCode: course['course_code'],
              # Convert the description to HTML.
              description: render_markdown(course['abstract']).presence,
              startDate: Array.wrap(course['start_date']),
              endDate: Array.wrap(course['end_date']),
              # Courses are available as self-paced courses once they ended,
              # and are not planned to be removed from the platform in advance.
              availableUntil: nil,
              image: image_data_for(course),
              instructors: instructors_for(course),
              duration: duration_for(course),
              # As the workload is not available as structured data, it's omitted.
              workload: nil,
              access: access_for(course),
              url: PublicCoursePage.url_for(course),
              trailer: teaser_data_for(course),
              courseMode: %w[online],
              inLanguage: Array.wrap(course['lang']),
              offers: offers_for(course),
              keywords: keywords_for(course),
              teaches: skills_for(course),
              educationalAlignment: educational_alignment_for(course),
              publisher: organization,
              creator: creator_for(course),
              license: licenses_for(course),
              learningResourceType: {
                identifier: 'https://w3id.org/kim/hcrt/course',
                type: 'Concept',
                inScheme: 'https://w3id.org/kim/hcrt/scheme',
              },
            }.compact,
          }
        end

        ALLOWED_ORG_KEYS  = %w[name url type description image].freeze
        REQUIRED_ORG_KEYS = %w[name url].freeze
        ALLOWED_IMG_KEYS  = %w[description type contentUrl license].freeze
        REQUIRED_IMG_KEYS = %w[contentUrl license].freeze

        private_constant :ALLOWED_ORG_KEYS, :REQUIRED_ORG_KEYS, :ALLOWED_IMG_KEYS, :REQUIRED_IMG_KEYS

        def organization
          org = @config.dig('course_metadata', 'organization')

          return if org.blank?
          # TODO: Add a fallback if the required values are missing.
          return if REQUIRED_ORG_KEYS.intersection(org.keys) != REQUIRED_ORG_KEYS

          img = @config.dig('course_metadata', 'organization', 'image')
          return if img.present? &&
                    (REQUIRED_IMG_KEYS.intersection(img.keys) != REQUIRED_IMG_KEYS)

          # Filter and compact image attributes (if applicable)
          org['image'] = img.slice(*ALLOWED_IMG_KEYS).compact if img.present?

          # Return filtered organization attributes
          # TODO: Add a fallback if the result is empty.
          org.slice(*ALLOWED_ORG_KEYS).compact
        end

        def creator_for(course)
          Rails.cache.fetch(
            "bridges/mooc_hub/creator/#{course['id']}",
            expires_in: 1.hour,
            race_condition_ttl: 1.minute
          ) do
            if course['teacher_ids'].any?
              @api.rel(:teachers).get({course: course['id']}).then do |teachers|
                # Return an array with the prefix and the actual name, e.g.
                # ['Prof. Dr.', 'Mustermann'] for 'Prof. Dr. Mustermann'.
                regex = /((?>Prof\.[[:blank:]]?)?(?>(?:PD)?[[:blank:]]?)?(?>Dr\.(?>-Ing\.)?[[:blank:]]?)*)(.*)/

                # Courses may have multiple teachers, so we return an array of JSON objects.
                teachers.filter_map do |teacher|
                  split_name = teacher['name'].split(regex).compact_blank.map(&:strip)

                  {
                    name: split_name[-1],
                    honorificPrefix: split_name[-2],
                    type: 'Person',
                    description: I18n.with_locale(course['lang'].to_sym) do
                      Translations.new(teacher['description']).to_s
                    end,
                  }.tap do |creator|
                    if teacher['picture_url'].present?
                      creator[:image] = {
                        type: 'ImageObject',
                        contentUrl: teacher['picture_url'],
                        license: @config.dig('course_metadata', 'creator', 'license'),
                      }
                    end
                  end
                end
              end.value!
            else
              Array.wrap(organization)
            end
          end
        end

        def image_data_for(course)
          visual = @course_visuals[course['id']]

          if visual&.image_url
            {
              type: 'ImageObject',
              contentUrl: visual.image_url,
              license: licenses_for(course),
            }
          else
            {
              type: 'ImageObject',
              contentUrl: @context.image_url('defaults/course.png'),
              license: [{
                identifier: 'CC0-1.0',
                url: 'https://creativecommons.org/publicdomain/zero/1.0',
                contentUrl: nil,
              }],
            }
          end
        end

        def teaser_data_for(course)
          visual = @course_visuals[course['id']]
          return unless visual&.video_stream

          {
            type: 'VideoObject',
            contentUrl: visual.video_stream.hd_url.presence || visual.video_stream.sd_url,
            license: licenses_for(course),
          }
        end

        def instructors_for(course)
          # Include teacher name only, omit image and description.
          course['teacher_text']&.split(',')&.map {|name| {name: name.strip} } || []
        end

        def keywords_for(course)
          return [] if course['classifiers'].blank?

          Catalog::Course.find(course['id']).classifiers('keywords')
        end

        def duration_for(course)
          return if course['start_date'].blank? || course['end_date'].blank?

          diff = Time.zone.parse(course['end_date']) - Time.zone.parse(course['start_date'])

          # Truncate to approximate full days using integer division.
          days = (diff / ActiveSupport::Duration::SECONDS_PER_DAY).to_i
          weeks, rest = days.divmod(7)
          weeks += 1 if rest >= 5

          # Since this is an approximation for the MOOCHub API, and
          # resembles the informal description of e.g. a 2W or 4W course,
          # we only return an approximation in weeks.
          duration = "P#{weeks == 0 ? "#{days.abs}D" : "#{weeks.abs}W"}"
          duration = "-#{duration}" if weeks.negative? || days.negative?
          duration
        end

        def skills_for(course)
          Course::Metadata.resolve(course['id'], Course::Metadata::TYPE::SKILLS, Course::Metadata::VERSION)
        end

        def educational_alignment_for(course)
          Course::Metadata.resolve(course['id'], Course::Metadata::TYPE::EDUCATIONAL_ALIGNMENT,
            Course::Metadata::VERSION)
        end

        ##
        # The course license can be provided per course. If it is not available,
        # fall back to the platform's default course license. When not configured,
        # indicate a proprietary license to be safe.
        #
        # @param course [Restify::Resource]
        def licenses_for(course)
          if Course::Course.find(course['id']).license.present?
            Course::Course.find(course['id']).license.data
          elsif (license = @config.dig('course_license', 'default'))
            [
              {
                identifier: license['id'],
                url: license['url'],
                contentUrl: nil,
              },
            ]
          else
            [
              {
                identifier: 'proprietary',
                url: nil,
                contentUrl: nil,
              },
            ]
          end
        end

        def access_for(course)
          return %w[free] unless paid?(course)

          %w[paid]
        end

        def offers_for(course)
          Course::Course.find(course['id']).offers.map do |offer|
            {
              price: offer.price,
              price_currency: offer.price_currency,
              payment_frequency: offer.payment_frequency,
              category: offer.category,
            }
          end
        rescue ActiveRecord::RecordNotFound
          []
        end

        def paid?(course)
          if Course::Course.find(course['id']).offers.any?
            offers_for(course).pluck(:price).sum.positive?
          else
            false
          end
        rescue ActiveRecord::RecordNotFound
          false
        end
      end
    end
  end
end

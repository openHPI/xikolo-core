# frozen_string_literal: true

module Xikolo
  module V2
    module Endpoint
      class ListNewsStatistics < Xikolo::API
        helpers do
          def percent(number, total)
            if (t = total.to_i) == 0
              0
            else
              number.to_i * 100 / t
            end
          end
        end

        desc 'Returns news stats'
        get do
          # authenticate!

          mail_log_stats = Xikolo.api(:notification).value!.rel(:mail_log_stats)
          news_index = Xikolo.api(:news).value!.rel(:news_index)

          news_list = if params[:course]
                        Xikolo.api(:course).value!
                          .rel(:course)
                          .get({id: params[:course]})
                          .then do |course|
                            news_index.get({
                              course_id: course['id'],
                              global_read_count: true,
                              per_page: 10,
                            })
                          end
                      elsif params[:global]
                        news_index.get({
                          global: true,
                          global_read_count: true,
                          per_page: 5,
                        })
                      else
                        news_index.get({
                          all_courses: true,
                          global_read_count: true,
                          per_page: 5,
                        })
                      end.value!

          statistics = news_list.map do |news|
            mail_log_stats.get({news_id: news.id}).then do |stats|
              state = if stats['count'].positive? && (stats['count'] >= news['receivers'] - 10)
                        'sent'
                      elsif stats['count'].positive? && stats['newest'] < 10.minutes.ago
                        'failed'
                      else
                        news['state']
                      end

              course_title = if (cid = news['course_id'])
                               Xikolo.api(:course).value!
                                 .rel(:course)
                                 .get({id: cid})
                                 .value!['title']
                             else
                               ''
                             end

              {
                id: news.fetch('id'),
                count: stats.fetch('count', 0),
                courseTitle: course_title,
                totalCount: news.fetch('receivers', 0),
                oldest: stats['oldest'],
                newest: stats['newest'],
                successCount: stats.fetch('success_count', 0),
                errorCount: stats.fetch('error_count', 0),
                disabledCount: stats.fetch('disabled_count', 0),
                uniqueCount: stats.fetch('unique_count', 0),
                state:,
                sendingState: news['sending_state'],
                newsTitle: news['title'],
                progress: percent(stats['unique_count'], news['receivers']),
                globalReadCount: news.fetch('read_count', 0),
                readstateProgress: percent(news['read_count'], stats['success_count']),
              }
            end
          end.map!(&:value!)

          {news_statistics: statistics}
        end
      end
    end
  end
end

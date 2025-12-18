# frozen_string_literal: true

namespace :xikolo do
  desc <<~DESC
    Export submission info to an excel, requires course_id: ENV['COURSE_ID']
  DESC
  require 'csv'

  task export_quizzes: :environment do
    @course_id = ENV.fetch('COURSE_ID', nil)
    @max_correct = 3
    @max_wrong = 4

    Dir.chdir(Dir.tmpdir) do
      filename = "quiz_export#{@course_id}.csv"
      @filepath = File.absolute_path(filename)
      puts @filepath
    end
    $stdout.print "Writing export to #{@filepath} \n"

    CSV.open(@filepath, 'wb') do |csv|
      # Table header
      csv << ['Quiz number',
              'Type (self_test - assignment - exam) for quizzes. (MultipleAnswer - MultipleChoice) for questions',
              'Name',
              'Points',
              'Question',
              'Correct Answer 1',
              'Explanation Correct Answer 1',
              'Correct Answer 2',
              'Explanation Correct Answer 2',
              'Correct Answer 3',
              'Explanation Correct Answer 3',
              'Wrong Answer 1',
              'Wrong Answer 1 CN',
              'Wrong Answer 2',
              'Wrong Answer 2 CN',
              'Wrong Answer 3',
              'Wrong Answer 3 CN',
              'Wrong Answer 4',
              'Wrong  Answer 4 CN',
              'Explanation',
              'Exclude']

      sections = []
      Xikolo.paginate(
        course_api.rel(:sections).get({course_id: @course_id})
      ) do |section|
        sections.push section['id']
      end

      count = 1
      quizzes = []
      sections.each do |section|
        Xikolo.paginate(
          course_api.rel(:items).get({section_id: section, content_type: 'quiz'})
        ) do |item|
          item_tmp = {}
          exercise_type = item['exercise_type'].presence || 'survey'
          item_tmp['quiz_index'] = count
          item_tmp['exercise_type'] = exercise_type
          item_tmp['title'] = item['title']
          item_tmp['quiz_id'] = item['content_id']
          quizzes.push(item_tmp)
          count += 1
        end
      end

      quizzes.each do |quiz|
        quiz['questions'] = QuizService::Question.where(quiz_id: quiz['quiz_id']).map do |question|
          question_tmp = {}
          question_tmp['q_id'] = question.id
          question_tmp['q_index'] = quiz['quiz_index']
          question_tmp['q_type'] = question.type
          question_tmp['q_points'] = question.points

          question_tmp['q_text'] = question.text

          if question.explanation.present?
            question_tmp['q_explanation'] = question.explanation
          end

          question_tmp
        end

        quiz['questions'].each do |quiz_question|
          quiz_question['correct_answers'] = []
          answers_c = QuizService::Answer.where(question_id: quiz_question['q_id'], correct: true)
          select_answers(quiz_question, answers_c, true, @max_correct)

          quiz_question['wrong_answers'] = []
          answers_w = QuizService::Answer.where(question_id: quiz_question['q_id'], correct: false)
          select_answers(quiz_question, answers_w, false, @max_wrong)
        end

        csv << [quiz['quiz_index'],
                quiz['exercise_type'],
                quiz['title'],
                '', '', '', '', '', '',
                '', '', '', '', '', '',
                '', '', '', '', '', '']
        quiz['questions'].each do |question|
          tmp = {}
          tmp['index'] = question['q_index']
          tmp['type'] = question['q_type'].scan(/^.*(?=Question)/).first
          tmp['points'] = question['q_points'].to_i
          tmp['title'] = question['q_text']
          tmp['q_explanation'] = question['q_explanation']

          a = 1
          question['correct_answers'].each do |ca|
            tmp["ca#{a}"] = ca['a_text']
            tmp["ca_c#{a}"] = ca['a_comment']
            a += 1
          end

          a = 1
          question['wrong_answers'].each do |wa|
            tmp["wa#{a}"] = wa['a_text']
            tmp["wa_c#{a}"] = wa['a_comment']
            a += 1
          end

          csv << [tmp['index'],
                  tmp['type'],
                  '',
                  tmp['points'],
                  tmp['title'],
                  tmp['ca1'],
                  tmp['ca_c1'],
                  tmp['ca2'],
                  tmp['ca_c2'],
                  tmp['ca3'],
                  tmp['ca_c3'],
                  tmp['wa1'],
                  tmp['wa_c1'],
                  tmp['wa2'],
                  tmp['wa_c2'],
                  tmp['wa3'],
                  tmp['wa_c3'],
                  tmp['wa4'],
                  tmp['wa_c4'],
                  tmp['q_explanation']]
        end
      end
    end
  end

  #
  # helpers
  #

  def select_answers(quiz_question, answers, correct, max)
    c_string = correct ? 'correct' : 'wrong'

    answers.take(max).each do |answer|
      answer_tmp = {}
      answer_tmp['a_text'] = answer.text
      answer_tmp['a_comment'] = answer.comment
      quiz_question["#{c_string}_answers"].push(answer_tmp)
    end

    if answers.count > max
      $stdout.print "Dropped #{c_string} answers for question: \n"
      $stdout.print "#{quiz_question['q_text']}\n"
      $stdout.print "Dropped answers: \n"
      answers.drop(max).each do |answer|
        $stdout.print "#{answer.text}\n"
        $stdout.print "Comment: \n"
        $stdout.print "#{answer.comment}\n"
      end
    end
  end

  def course_api
    @course_api ||= Xikolo.api(:course).value!
  end
end

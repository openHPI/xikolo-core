# frozen_string_literal: true

module Steps::Gradings
  def create_rubric
    data = {
      peer_assessment_id: context.fetch(:assessment)['id'],
      title: 'A specific rubric',
      hints: 'A useful hint',
      team_evaluation: false,
    }
    Server[:peerassessment].api.rel(:rubrics).post(data).value!
  end

  def create_rubric_options(rubric_id)
    options = []
    options << Server[:peerassessment].api.rel(:rubric_options).post(rubric_id:,
      description: 'Excellent',
      points: 3).value!
    options << Server[:peerassessment].api.rel(:rubric_options).post(rubric_id:,
      description: 'Good',
      points: 2).value!
    options << Server[:peerassessment].api.rel(:rubric_options).post(rubric_id:,
      description: 'Improvement needed',
      points: 1).value!
    options
  end

  def get_rubric_option_ids(rubric_id)
    Server[:peerassessment].api.rel(:rubric_options).get(rubric_id:).value!
  end

  Given 'there are grading rubrics and options' do
    # Create three rubrics with three options each
    context.assign :rubrics, rubrics = Array.new(3) { create_rubric }
    options = []
    rubrics.each {|rubric| options += create_rubric_options(rubric['id']) }
    context.assign :rubric_options, options
  end
end

Gurke.config.include Steps::Gradings

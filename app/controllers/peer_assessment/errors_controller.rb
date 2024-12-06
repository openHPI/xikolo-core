# frozen_string_literal: true

class PeerAssessment::ErrorsController < PeerAssessment::BaseController
  inside_course
  inside_item
  inside_assessment_skip_checks

  def show
    Acfs.run
  end
end

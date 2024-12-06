# frozen_string_literal: true

#
# Controller handling AJAX stuff for peer assessment teacher notes.
#
class PeerAssessment::NotesController < Abstract::AjaxController
  include PeerAssessment::PeerAssessmentContextHelper

  before_action { authorize! 'peerassessment.conflicts.manage' }

  def create
    form = PeerAssessment::NoteForm.new(note_params)

    if form.valid?
      note = form.as_json
      note['user_id'] = current_user.id
      post = pa_api.rel(:notes).post(note).value!
    end

    if post.response.code == 201
      render json: {
        id: post['id'],
                 created_at: "#{I18n.l(post['created_at'].to_datetime, format: :short)} (#{Time.zone.name}):",
                 text: post['text'],
                 author: current_user.full_name,
      }.to_json
    else
      render json: {message: I18n.t(:'peer_assessment.notes.create_error')}, status: :bad_request
    end
  end

  def update
    note = pa_api.rel(:note).get(id: params[:id]).value!
    note['text'] = params[:text]

    unless current_user.id == note['user_id']
      return render json: {error: I18n.t(:'peer_assessment.notes.not_allowed')}, status: :forbidden
    end

    if api.rel(:note).put({text: params[:text]}, {id: params[:id]}).value!.response.code == 204
      render json: note.to_json
    else
      render json: {message: I18n.t(:'peer_assessment.notes.update_error')}, status: :bad_request
    end
  end

  def destroy
    note = pa_api.rel(:note).get(id: params[:id]).value!

    unless current_user.id == note['user_id']
      return render json: {error: I18n.t(:'peer_assessment.notes.not_allowed')}, status: :forbidden
    end

    if pa_api.rel(:note).delete(id: params[:id]).value!.response.code == 204
      render json: {id: note['id']}
    else
      render json: {status: :error, message: I18n.t(:'peer_assessment.notes.destroy_error')}
    end
  end

  private

  def note_params
    params.require(:peer_assessment_note_form).permit(:text, :subject_id, :subject_type)
  end

  def auth_context
    conflict_id = params['peer_assessment_note_form']['subject_id']
    conflict = pa_api.rel(:conflict).get(id: conflict_id).value!
    pa = pa_api.rel(:peer_assessment).get(id: conflict['peer_assessment_id']).value!
    course = Xikolo.api(:course).value!.rel(:course).get(id: pa['course_id']).value!
    course['context_id']
  end
end

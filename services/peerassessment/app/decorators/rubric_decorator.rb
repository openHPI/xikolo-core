# frozen_string_literal: true

class RubricDecorator < Draper::Decorator
  delegate_all

  def as_json(opts = {})
    {
      id:,
      peer_assessment_id:,
      hints:,
      title:,
      position:,
    }.as_json(opts)
  end

  def hints
    if context[:raw]
      Xikolo::S3.media_refs(object.hints, public: true)
        .merge('markup' => object.hints)
    else
      Xikolo::S3.externalize_file_refs(object.hints, public: true)
    end
  end
end

# frozen_string_literal: true

class PostDecorator < Draper::Decorator
  delegate_all

  def as_json(opts)
    {
      **fields,
      **urls,
    }.as_json(opts)
  end

  private

  def fields
    {
      id:,
      author_id:,
      created_at:,
      text:,
      blocked: blocked?,
      upvotes: votes.where(value: 1).count,
    }.tap do |fields|
      fields[:downvotes] = votes.where(value: -1).count if object.downvotes?
    end
  end

  def urls
    {
      url: h.post_path(id),
      reports_url: h.abuse_reports_path(reportable_type: object.class.name, reportable_id: id),
      user_votes_url: h.post_user_vote_rfc6570.partial_expand(post_id: id),
    }
  end

  def text
    if raw?
      Xikolo::S3.media_refs(object.text, public: true)
        .merge('markup' => object.text)
    else
      Xikolo::S3.externalize_file_refs(object.text, public: true)
    end
  end

  def raw?
    context[:raw]
  end
end

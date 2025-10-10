# frozen_string_literal: true

module AccountService
class API::ContextsController < API::RESTController # rubocop:disable Layout/IndentationWidth
  respond_to :json

  rfc6570_params index: %i[ancestors ascent]
  def index
    if params.key? :ancestors
      ctx = Context.resolve(params[:ancestors])
      respond_with ctx.ancestors
    elsif params.key? :ascent
      ctx = Context.resolve(params[:ascent])
      respond_with ctx.ascent
    else
      respond_with collection
    end
  end

  def create
    context = Context.create create_params.merge(parent: parent_context)
    respond_with context
  end

  def show
    respond_with resource
  end

  def decorate(resources)
    if resources.respond_to? :decorate
      resources.decorate
    elsif resources.respond_to? :each
      Array(resources).map {|res| decorate(res) }
    else
      resources
    end
  end

  private

  def create_params
    params.permit(:reference_uri)
  end

  def parent_context
    Context.resolve(params[:parent] || 'root')
  end
end
end

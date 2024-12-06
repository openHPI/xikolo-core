# frozen_string_literal: true

require 'spec_helper'

describe ErrorsController, type: :controller do
  # We use `params: {use_route: :root}` to force the controller test helper to
  # use `root_url` to "create" a URL for the fake request. Without it, Rails
  # would try to use the controller and action name to derive a URL, which will
  # fail, as ErrorsController#show isn't reachable by any route in `routes.rb`.

  render_views

  let(:html) do
    # Parse the response body as an HTML fragment and make it into a capybara
    # node so that we can use all nice matchers.
    Capybara.string(response.body)
  end

  describe '#show' do
    it 'attaches the exception to mnemosyne' do
      exception = instance_double(Exception)
      expect(Mnemosyne).to receive(:attach_error).with(exception)

      request.env['PATH_INFO'] = '/404'
      request.env['action_dispatch.exception'] = exception
      get :show, params: {use_route: :root}
    end

    context 'with 404' do
      before do
        request.env['PATH_INFO'] = '/404'
        get :show, params: {use_route: :root}
      end

      it 'answers with a page' do
        expect(response).to have_http_status :not_found
        expect(response.headers['Content-Type']).to eq 'text/html; charset=utf-8'

        expect(html).to have_content <<~TEXT.squish
          We are sorry, but the page you are looking for could not be found
        TEXT

        expect(html).to have_content <<~TEXT.squish
          Please check the URL. If you really think this is a bug, feel free
          to contact our support team through the helpdesk.
        TEXT
      end
    end

    context 'with 500' do
      before do
        request.env['PATH_INFO'] = '/500'
        get :show, params: {use_route: :root}
      end

      it 'answers with a page' do
        expect(response).to have_http_status :internal_server_error
        expect(response.headers['Content-Type']).to eq 'text/html; charset=utf-8'

        expect(html).to have_content <<~TEXT.squish
          We are afraid something went wrong
        TEXT

        expect(html).to have_content <<~TEXT.squish
          You might want to try again later. This error will be reported to our
          tech team automatically. However you might want to help us by submitting
          some details about what went wrong through the helpdesk.
        TEXT
      end
    end

    context 'with text format' do
      before do
        request.env['PATH_INFO'] = '/404'
        get :show, params: {use_route: :root, format: 'txt'}
      end

      it 'answers with plain text' do
        expect(response).to have_http_status :not_found
        expect(response.headers['Content-Type']).to eq 'text/plain; charset=utf-8'
        expect(response.body).to eq <<~TEXT
          We are sorry, but the page you are looking for could not be found (404)

          Please check the URL. If you really think this is a bug, feel free to contact
          our support team through the helpdesk.


          http://test.host/helpdesk
        TEXT
      end
    end

    context 'with any other format' do
      before do
        request.env['PATH_INFO'] = '/404'
        get :show, params: {use_route: :root, format: 'png'}
      end

      it 'answers with plain text' do
        expect(response).to have_http_status :not_found
        expect(response.headers['Content-Type']).to eq 'text/plain; charset=utf-8'
        expect(response.body).to eq <<~TEXT
          We are sorry, but the page you are looking for could not be found (404)

          Please check the URL. If you really think this is a bug, feel free to contact
          our support team through the helpdesk.


          http://test.host/helpdesk
        TEXT
      end
    end

    context 'with JSON format' do
      before do
        request.env['PATH_INFO'] = '/404'
        get :show, params: {use_route: :root, format: 'json'}
      end

      it 'answers with a Problem Details (RFC 7807) document' do
        expect(response).to have_http_status :not_found
        expect(response.media_type).to eq 'application/problem+json'
        expect(JSON.parse(response.body)).to eq({
          'title' => 'We are sorry, but the page you are looking for could not be found (404)',
          'detail' => <<~TEXT.squish,
            Please check the URL. If you really think this is a bug, feel free
            to contact our support team through the helpdesk.
          TEXT
          'status' => 404,
        })
      end
    end
  end
end

# frozen_string_literal: true

class Successfactors::API
  REQUEST_TOKEN_URL   = '/learning/oauth-api/rest/v1/token'
  PUBLISH_COURSES_URL = '/learning/odatav4/public/admin/ocn/v1/OcnCourses'

  def initialize(name, config)
    @config = config
    @token_cache_key = "#{name.parameterize(separator: '_')}:successfactors:token"
  end

  def post_courses(data)
    api_request(
      PUBLISH_COURSES_URL,
      request_headers.merge(access_token_auth_header),
      data
    )
  end

  private

  def basic_auth_header
    auth_value = Base64.encode64("#{@config['client_id']}:#{@config['client_secret']}").delete("\n")

    {Authorization: "Basic #{auth_value}"}
  end

  def request_headers
    {
      'Content-Type': 'application/json',
      'Accept-Encoding': 'gzip',
    }
  end

  def token_body
    {
      grant_type: 'client_credentials',
      scope: {
        userId: @config['user_id'],
        companyId: @config['company_id'],
        userType: 'admin',
        resourceType: 'learning_public_api',
      },
    }.to_json
  end

  def token
    Rails.cache.read(@token_cache_key) || request_token
  end

  def request_token
    response = api_request(
      REQUEST_TOKEN_URL,
      request_headers.merge(basic_auth_header),
      token_body
    )

    token_data = JSON.parse response.body
    cache_token token_data
    token_data['access_token']
  end

  def cache_token(token_data)
    Rails.cache.write(
      @token_cache_key,
      token_data['access_token'],
      expires_in: token_data['expires_in']
    )
    token_data['access_token']
  end

  def access_token_auth_header
    {Authorization: "Bearer #{token}"}
  end

  def api_request(api_action, headers, body)
    request = Typhoeus::Request.new(
      @config['base_url'] + api_action,
      method: :post,
      body:,
      headers:,
      accept_encoding: 'gzip'
    )

    response = request.run
    raise APIError.new(response) if response.code >= 400

    response
  end
end

class APIError < StandardError
  def initialize(response)
    response_body = JSON.parse(response.body)
    if response_body.key? 'error'
      raw_error = response_body['error']
      error_code = raw_error['errorCode'] ||
                   raw_error['code'] ||
                   response.code

      err = "ERROR #{error_code}: #{raw_error['message']}"
    else
      err = "ERROR #{response.code}: unknown error"
    end

    super(err)
  end
end

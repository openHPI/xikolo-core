# frozen_string_literal: true

module Xikolo
  module V2
    class TokenAPI < Grape::API::Instance
      namespace 'authenticate' do
        desc 'Retrieve a token after identifying a user'
        params do
          requires :email, type: String
          requires :password, type: String
        end
        post do
          begin
            # Create a new session...
            session = Xikolo.api(:account).value!.rel(:sessions).post({
              ident: params[:email],
              password: params[:password],
            }).value!
          rescue Restify::ClientError
            raise Xikolo::Error::Unauthorized.new 401, 'Invalid credentials'
          end

          raise Xikolo::Error::Unauthorized.new 401, 'This user cannot receive tokens' unless session.rel? :tokens

          # ...and finally, retrieve the token for this session
          token = session.rel(:tokens).post.value!

          {token: token['token'], user_id: token['user_id']}
        end
      end
    end
  end
end

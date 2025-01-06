# frozen_string_literal: true

class FilesController < ApplicationController
  # The user is not needed to serve a file
  skip_around_action :auth_middleware

  def avatar
    user = Xikolo::Account::User.find params[:id]
    Acfs.run
    if user.present? && user.avatar_url
      url = user.avatar_url
    else
      url = view_context.image_url("defaults/#{requested_user_image_size}.png")
    end
    imagecrop_params = params.permit(:height, :width).to_h.compact
    if imagecrop_params.any?
      redirect_external Imagecrop.transform(url, {'gravity' => 'ce'}.merge(imagecrop_params))
    else
      redirect_external(url)
    end
  end

  def logo
    expires_in 1.month, public: true

    if params[:email]
      redirect_external view_context.image_url('logo_mail.png'), status: :found
    else
      redirect_external view_context.image_url('logo.png'), status: :found
    end
  end

  def favicon
    expires_in 1.month, public: true
    redirect_external view_context.image_url('favicon.ico'), status: :found
  end

  def sitemap
    redirect_external Xikolo::S3.bucket_for(:sitemaps).object('sitemaps/sitemap.xml.gz').public_url
  end

  private

  USER_IMAGE_SIZES = {
    'user_small'  => 60,
    'user_medium' => 100,
    'user_large'  => 200,
  }.freeze

  def requested_user_image_size
    return 'user_medium' unless USER_IMAGE_SIZES.key? params[:size]

    params[:size]
  end
end

# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include Pagy::Backend

  protect_from_forgery with: :exception
  before_action :authenticate_user!
  before_action :configure_permitted_parameters, if: :devise_controller?
  after_action :prepare_flash_messages

  private

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:full_name])
    devise_parameter_sanitizer.permit(:account_update, keys: [:full_name])
  end

  def prepare_flash_messages
    return unless turbo_frame_request?

    flash.each do |_key, _message|
      turbo_stream.replace 'flash-messages', partial: 'shared/flash'
    end

    flash.discard
  end
end

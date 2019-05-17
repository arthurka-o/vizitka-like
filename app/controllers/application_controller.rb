class ApplicationController < ActionController::API
  before_action :ensure_user

  def invalid_credentials
    render json: { code: 20, message: 'Invalid credentials'},
           status: Rack::Utils.status_code(:unauthorized)
  end

  def invalid_token
    render json: { code: 20, message: 'Invalid token' },
           status: Rack::Utils.status_code(:unauthorized)
  end

  private

    def ensure_user
      return invalid_token unless request.headers['Authorization'].present? || params[:api_key]

      if params[:api_key]
        @token = params[:api_key]
        @user = Publisher.where(api_key: @token).first
        return invalid_token unless @user
      else
        authenticate_or_request_with_http_token do |token, options|
          @token = token
          @user = Publisher.where(api_key: @token).first
          return invalid_token unless @user
          true
        end
      end
    end
    
end

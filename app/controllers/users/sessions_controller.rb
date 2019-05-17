class Users::SessionsController < ActionController::API
  include Devise::Controllers::SignInOut

  def create
    user = User.find_for_database_authentication(email: session_params[:email])
    if user.present? && user.valid_password?(session_params[:password])
      sign_in(:user, user)
      render json: MultiSerializer.new(user: user).object.to_json
    else
      invalid_credentials
    end
  end

  def destroy
    user = current_user

    if user.present?
      sign_out(user)

      render json: user
    else
      head :forbidden
    end
  end

  private

  def session_params
    params.require(:session).permit(:email, :password)
  end
end

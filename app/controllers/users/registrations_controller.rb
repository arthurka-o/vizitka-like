class Users::RegistrationsController < ActionController::API
  include Devise::Controllers::SignInOut

  def create
    user = User.new(user_params)

    ActiveRecord::Base.transaction do
      if user.save
        sign_in(:user, user)
        
        render json: MultiSerializer.new(user: user).object.to_json
      else
        render json: user.errors, status: :unprocessable_entity
        raise ActiveRecord::Rollback
      end
    end
  end

  private

    def user_params
      params.require(:user).permit(:name, :surname, :organization, :email, :password, :password_confirmation)
    end
end

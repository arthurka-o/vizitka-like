class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  before_create :ensure_api_keys

  private

    def ensure_api_keys
      self.api_key = SecureRandom.hex
    end
end

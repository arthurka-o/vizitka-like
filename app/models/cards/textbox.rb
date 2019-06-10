class Cards::Textbox < ApplicationRecord
  belongs_to :card, dependent: :destroy
end
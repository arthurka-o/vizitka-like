class Cards::Image < ApplicationRecord
  belongs_to :card, dependent: :destroy

  mount_uploader :mediafile, MediaUploader
end
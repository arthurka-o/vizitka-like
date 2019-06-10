class Card < ApplicationRecord
  mount_uploader :background, MediaUploader

  has_many :images
  has_many :textboxes

  accepts_nested_attributes_for :images, allow_destroy: true 
  accepts_nested_attributes_for :textboxes, allow_destroy: true
end
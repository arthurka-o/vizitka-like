class AddCoordinatesToImagesAndTextboxes < ActiveRecord::Migration[5.2]
  def change
    add_column :cards_textboxes, :x, :integer, default: 0
    add_column :cards_textboxes, :y, :integer, default: 0

    add_column :cards_images, :x, :integer, default: 0
    add_column :cards_images, :y, :integer, default: 0
  end
end

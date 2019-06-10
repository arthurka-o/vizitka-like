class CreateCardsTextboxes < ActiveRecord::Migration[5.2]
  def change
    create_table :cards_textboxes do |t|
      t.references :card
      t.string :name, null: false
      t.string :value, default: ''
      t.integer :height, default: 0
      t.integer :width, default: 0

      t.timestamp
    end
  end
end

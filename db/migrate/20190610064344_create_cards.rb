class CreateCards < ActiveRecord::Migration[5.2]
  def change
    create_table :cards do |t|
      t.string :name, null: :false
      t.integer :weidth, default: 0
      t.integer :height, default: 0
      t.string :background
      
      t.timestamp
    end
  end
end

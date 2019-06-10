class CreateOrders < ActiveRecord::Migration[5.2]
  def change
    create_table :orders do |t|
      t.string :name, null: false
      t.string :phone_number, null: false
      t.text :message, null: false
    end
  end
end

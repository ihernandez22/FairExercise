class CreateTransactions < ActiveRecord::Migration[5.1]
  def change
    create_table :transactions do |t|
      t.date :date, null: false
      t.string :transaction_type, null: false
      t.float :amount, null: false
      t.integer :credit_card_id, null: false

      t.timestamps
    end
  end
end

class CreateCreditCards < ActiveRecord::Migration[5.1]
  def change
    create_table :credit_cards do |t|
      t.string :name, null: false
      t.date :current_payment_period_start_date, null: false

      t.timestamps
    end
  end
end

class CreateBorrowings < ActiveRecord::Migration[8.0]
  def change
    create_table :borrowings do |t|
      t.integer :student_id
      t.integer :book_id
      t.datetime :borrowed_at
      t.datetime :due_at
      t.boolean :returned

      t.timestamps
    end
  end
end

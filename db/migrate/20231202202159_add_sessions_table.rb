class AddSessionsTable < ActiveRecord::Migration[7.0]
  def change
    create_table :sessions do |t|
      t.string :session_id, null: false, unique: true
      t.text :data
      t.timestamps
    end
  end
end

class AddRoleToUsers < ActiveRecord::Migration[7.2]
  # Role is stored as an integer enum: 0=admin, 1=editor, 2=author.
  # Default is author (least privilege for new signups).
  # null: false enforces the invariant at the DB level.
  def change
    add_column :users, :role, :integer, null: false, default: 2
    add_index  :users, :role
  end
end

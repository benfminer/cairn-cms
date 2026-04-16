class CreatePosts < ActiveRecord::Migration[7.2]
  # status: 0=draft (default), 1=in_review, 2=published, 3=archived
  # author_id references users — to_table: :users required (not :authors)
  # Composite index on (author_id, status) covers the most common query pattern
  def change
    create_table :posts do |t|
      t.string  :title,  null: false
      t.integer :status, null: false, default: 0
      t.references :author, null: false, foreign_key: { to_table: :users }
      t.timestamps
    end

    add_index :posts, %i[author_id status]
  end
end

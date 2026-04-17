class AddDiscardedAtToPosts < ActiveRecord::Migration[7.2]
  def change
    add_column :posts, :discarded_at, :datetime
    add_index :posts, :discarded_at, name: "index_posts_on_discarded_at"
  end
end

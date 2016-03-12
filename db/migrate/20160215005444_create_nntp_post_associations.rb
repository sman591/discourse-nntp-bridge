class CreateNntpPostAssociations < ActiveRecord::Migration
  def change
    create_table :discourse_nntp_bridge_nntp_posts do |t|
      t.belongs_to :post, index: true
      t.string :message_id, index: true
      t.timestamps null: false
    end
  end
end

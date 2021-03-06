# frozen_string_literal: true

class CreateNntpPostAssociations < ActiveRecord::Migration[4.2]
  def change
    create_table :discourse_nntp_bridge_nntp_posts do |t|
      t.belongs_to :post, index: true
      t.string :message_id, index: true
      t.timestamps null: false
    end
  end
end

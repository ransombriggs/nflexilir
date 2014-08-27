class CreatePlayers < ActiveRecord::Migration
  def change
    create_table :players do |t|
      t.string :name
      t.string :position
      t.references :team
      t.integer :stats
      t.integer :proj
      t.integer :player_id
      t.integer :claimed_by
      t.integer :rank
      t.datetime :claim_time
      t.timestamps
    end
  end
end

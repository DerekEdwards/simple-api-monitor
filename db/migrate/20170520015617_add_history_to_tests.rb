class AddHistoryToTests < ActiveRecord::Migration[5.0]
  def change
  	add_column :tests, :history, :text
  end
end

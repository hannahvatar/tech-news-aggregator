class CreateReports < ActiveRecord::Migration[7.1]
  def change
    create_table :reports do |t|
      t.string :report_type
      t.string :detail_level
      t.text :data

      t.timestamps
    end
  end
end

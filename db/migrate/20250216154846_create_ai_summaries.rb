# db/migrate/20250216154846_create_ai_summaries.rb
class CreateAiSummaries < ActiveRecord::Migration[7.1]
  def change
    create_table :ai_summaries do |t|
      t.references :article, null: false, foreign_key: true
      t.text :content
      t.datetime :generated_at

      t.timestamps
    end
  end
end

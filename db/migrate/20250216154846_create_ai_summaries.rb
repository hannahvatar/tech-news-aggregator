class CreateAiSummaries < ActiveRecord::Migration[7.1]
  def change
    create_table :ai_summaries do |t|

      t.timestamps
    end
  end
end

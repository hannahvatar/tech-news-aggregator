class AddSummarizableTypeAndIdToAiSummaries < ActiveRecord::Migration[7.1]
  def change
    add_column :ai_summaries, :summarizable_type, :string
    add_column :ai_summaries, :summarizable_id, :bigint
  end
end

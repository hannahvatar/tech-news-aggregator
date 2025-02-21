class RemovePolymorphicColumnsFromAiSummaries < ActiveRecord::Migration[7.1]
  def change
    remove_column :ai_summaries, :summarizable_type, :string
    remove_column :ai_summaries, :summarizable_id, :bigint
  end
end

class AddSummarizableToAiSummaries < ActiveRecord::Migration[6.0]
  def change
    add_reference :ai_summaries, :summarizable, polymorphic: true, null: true
  end
end

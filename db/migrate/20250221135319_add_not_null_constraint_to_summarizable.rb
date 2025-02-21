class AddNotNullConstraintToSummarizable < ActiveRecord::Migration[6.0]
  def change
    change_column_null :ai_summaries, :summarizable_type, false
  end
end

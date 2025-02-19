class RemoveUnusedColumnsFromReports < ActiveRecord::Migration[7.1]
  def change
    remove_column :reports, :report_type, :string
    remove_column :reports, :detail_level, :string
  end
end

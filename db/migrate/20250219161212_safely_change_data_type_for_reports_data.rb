class SafelyChangeDataTypeForReportsData < ActiveRecord::Migration[7.1]
  def up
    # First add a new JSONB column
    add_column :reports, :data_jsonb, :jsonb, default: {}

    # Update data for each record
    Report.find_each do |report|
      begin
        case report.data
        when Hash
          # If it's already a Hash, use it directly
          report.update_column(:data_jsonb, report.data)
        when String
          if report.data.start_with?('{') && report.data.end_with?('}')
            # If it's a JSON string, parse it
            parsed_data = JSON.parse(report.data)
            report.update_column(:data_jsonb, parsed_data)
          else
            # For plain text, wrap it in a content object
            report.update_column(:data_jsonb, { content: report.data.presence || {} })
          end
        else
          # For nil or other types, use empty object
          report.update_column(:data_jsonb, {})
        end
      rescue JSON::ParserError => e
        # If JSON parsing fails, store as content
        report.update_column(:data_jsonb, { content: report.data.to_s })
      end
    end

    # Remove old column and rename new one
    remove_column :reports, :data
    rename_column :reports, :data_jsonb, :data
  end

  def down
    # Revert the changes if needed
    change_column :reports, :data, :text
  end
end

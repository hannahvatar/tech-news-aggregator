# app/controllers/reports_controller.rb
class ReportsController < ApplicationController
  def generate_ai_summary
    report_service = AiSummaryReportService.new(params[:timeframe]&.to_time || 1.week.ago)
    filename = report_service.save_report

    send_file Rails.root.join('tmp', filename),
              type: 'text/plain',
              disposition: 'attachment',
              filename: filename
  end
end

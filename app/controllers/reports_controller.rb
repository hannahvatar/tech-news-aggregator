class ReportsController < ApplicationController
  def generate
    # Validate input parameters
    start_date = params[:start_date]
    end_date = params[:end_date]
    report_type = params[:report_type]
    detail_level = params[:detail_level]
    include_visualizations = params[:include_visualizations] == '1'

    # Log the form params for debugging
    Rails.logger.info "Received form params: #{params.inspect}"

    # Input validation
    if start_date.blank? || end_date.blank?
      flash[:error] = "Please select both start and end dates"
      return redirect_to new_report_path
    end

    begin
      # Parse the dates and handle errors
      start_date = Date.parse(start_date)
      end_date = Date.parse(end_date)

      # Log parsed dates for debugging
      Rails.logger.info "Parsed dates: Start - #{start_date}, End - #{end_date}"

      # Ensure date range is valid
      if end_date < start_date || (end_date - start_date).to_i > 30
        flash[:error] = "Invalid date range. Please select a range up to 30 days."
        return redirect_to new_report_path
      end

      # Fetch the report data based on report type and detail level
      @report_data = Report.fetch_report_data(report_type, detail_level)

      # Log the fetched report data for debugging
      Rails.logger.info "Fetched report data: #{@report_data.inspect}"

      # Check if there is data available for the selected parameters
      if @report_data.blank?
        flash[:error] = "No data found for the selected criteria."
        return redirect_to new_report_path
      end

      # Generate the report (PDF file)
      report_service = ReportGenerationService.new(start_date, end_date)
      pdf_path = report_service.generate_report(
        report_type: report_type,
        detail_level: detail_level,
        include_visualizations: include_visualizations
      )

      # Log the path of the generated report
      Rails.logger.info "Generated report file at: #{pdf_path}"

      # Store the file path in the session or another temporary storage
      session[:generated_report_path] = pdf_path

      # Redirect to the show page to view the report
      flash[:success] = "Report generated successfully! You can now view it."
      redirect_to view_report_path # Redirect to view action

    rescue ArgumentError => e
      flash[:error] = "Invalid date format. Please use a valid date format (YYYY-MM-DD)."
      redirect_to new_report_path
    rescue => e
      Rails.logger.error "Report Generation Error: #{e.message}"
      flash[:error] = "Error generating report. Please try again."
      redirect_to new_report_path
    end
  end

  def view
    # Ensure that the report file path exists in the session
    if session[:generated_report_path].present?
      pdf_path = session.delete(:generated_report_path)

      # Check if the file exists before attempting to send it
      if File.exist?(pdf_path)
        # Send the file for viewing in the browser (inline)
        send_file pdf_path,
                  filename: "tech_insights_report.pdf",
                  type: 'application/pdf',
                  disposition: 'inline' # This makes it open in the browser instead of downloading
      else
        flash[:error] = "Report file not found."
        redirect_to new_report_path
      end
    else
      flash[:error] = "No report available to view."
      redirect_to new_report_path
    end
  end
end

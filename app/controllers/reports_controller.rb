class ReportsController < ApplicationController
  before_action :validate_report_params, only: [:generate]

  def new
    # Initialize any form-specific variables if needed
  end

  def generate
    # Extensive logging for debugging
    Rails.logger.debug "Starting report generation"
    Rails.logger.debug "Raw params: #{params.inspect}"

    begin
      # Prepare parameters with more robust conversion
      prepared_params = {
        start_date: params[:start_date],
        end_date: params[:end_date],
        report_type: params[:report_type],
        detail_level: params[:detail_level],
        include_visualizations: params[:include_visualizations] == '1'
      }

      Rails.logger.debug "Prepared params: #{prepared_params.inspect}"

      # Use prepared params instead of report_params
      result = ReportGenerationService.new(prepared_params.with_indifferent_access).generate

      # Log the result of report generation
      Rails.logger.debug "Report generation result: #{result.inspect}"

      # Handle generation errors
      unless result[:success]
        flash.now[:error] = result[:error] || 'Failed to generate report'
        Rails.logger.error "Report generation failed: #{result[:error]}"
        return render :new
      end

      # Create the report record
      @report = Report.create!(
        report_type: prepared_params[:report_type],
        detail_level: prepared_params[:detail_level],
        start_date: prepared_params[:start_date],
        end_date: prepared_params[:end_date],
        data: result.to_json
      )

      # Log successful report creation
      Rails.logger.info "Report generated successfully: ID #{@report.id}"

      # Redirect to the report view
      flash[:success] = 'Report generated successfully'
      redirect_to report_path(@report)

    rescue ActiveRecord::RecordInvalid => e
      # Handle database validation errors
      Rails.logger.error "Report creation failed: #{e.message}"
      flash.now[:error] = "Could not save report: #{e.message}"
      render :new

    rescue StandardError => e
      # Catch and log any unexpected errors
      Rails.logger.error "Unexpected error in report generation: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")

      flash.now[:error] = "An unexpected error occurred: #{e.message}"
      render :new
    end
  end

  def show
    # Find the report
    @report = Report.find_by(id: params[:id])

    # Handle report not found
    if @report.nil?
      flash[:error] = 'Report not found'
      redirect_to new_report_path
      return
    end

    begin
      # Log the raw data for debugging
      Rails.logger.debug "Raw report data: #{@report.data}"

      # Parse the JSON data
      parsed_data = JSON.parse(@report.data, symbolize_names: true)
      Rails.logger.debug "Parsed data: #{parsed_data.inspect}"

      # Extract report data and metadata
      if parsed_data[:success]
        @report_data = parsed_data[:data] || {}
        @metadata = parsed_data[:metadata] || {}
      else
        # Fallback for unexpected data structure
        @report_data = parsed_data
        @metadata = {
          article_count: 0,
          date_range: 'Unknown',
          report_type: @report.report_type,
          detail_level: @report.detail_level
        }
      end

      # Additional logging for debugging
      Rails.logger.debug "Report Data Keys: #{@report_data.keys}"
      Rails.logger.debug "Metadata Keys: #{@metadata.keys}"

    rescue JSON::ParserError => e
      # Handle JSON parsing errors
      Rails.logger.error "JSON parsing error: #{e.message}"
      flash[:error] = 'Failed to parse report data'
      redirect_to new_report_path
      return

    rescue StandardError => e
      # Catch any unexpected errors
      Rails.logger.error "Unexpected error in show action: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      flash[:error] = 'An unexpected error occurred while loading the report'
      redirect_to new_report_path
      return
    end

    # Final check for empty data
    if @report_data.blank?
      flash[:error] = 'Report data is incomplete'
      redirect_to new_report_path
    end
  end

  private

  def validate_report_params
    Rails.logger.debug "Validating report params: #{params.inspect}"

    required_params = [:start_date, :end_date, :report_type, :detail_level]

    missing_params = required_params.select { |param| params[param].blank? }

    if missing_params.any?
      error_message = "The following parameters are required: #{missing_params.map(&:to_s).join(', ')}"
      Rails.logger.error error_message
      flash.now[:error] = error_message
      render :new and return false
    end

    # Additional parameter validation
    begin
      Date.parse(params[:start_date])
      Date.parse(params[:end_date])
    rescue ArgumentError
      flash.now[:error] = "Invalid date format. Please use YYYY-MM-DD."
      render :new and return false
    end

    true
  end

  def report_params
    params.permit(
      :start_date,
      :end_date,
      :report_type,
      :detail_level,
      :include_visualizations
    )
  end
end

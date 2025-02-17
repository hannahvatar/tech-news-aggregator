class ReportsController < ApplicationController
  before_action :validate_report_params, only: [:generate]

  def new
    # Initialize any form-specific variables if needed
  end

  def generate
    # Log the incoming parameters for debugging
    Rails.logger.info "Generating report with params: #{report_params.inspect}"

    # Pass the parameters as a hash with indifferent access
    result = ReportGenerationService.new(report_params.to_h.with_indifferent_access).generate

    # Handle generation errors
    if result[:success] == false
      flash.now[:error] = result[:error] || 'Failed to generate report'
      Rails.logger.error "Report generation failed: #{result[:error]}"
      render :new and return
    end

    # Create the report record
    begin
      @report = Report.create!(
        report_type: report_params[:report_type],
        detail_level: report_params[:detail_level],
        start_date: report_params[:start_date],
        end_date: report_params[:end_date],
        data: result.to_json # Ensure the data is stored as a JSON string
      )

      # Log successful report creation
      Rails.logger.info "Report generated successfully: ID #{@report.id}"

      # Redirect to the report view
      flash[:success] = 'Report generated successfully'
      redirect_to report_path(@report)

    rescue ActiveRecord::RecordInvalid => e
      # Handle database validation errors
      flash.now[:error] = "Could not save report: #{e.message}"
      Rails.logger.error "Report creation failed: #{e.message}"
      render :new
    end
  end

  def show
    @report = Report.find_by(id: params[:id])

    if @report.nil?
      flash[:error] = 'Report not found'
      redirect_to new_report_path
      return
    end

    begin
      # Parse the entire data structure
      parsed_data = JSON.parse(@report.data, symbolize_names: true)

      # Debugging log
      Rails.logger.debug "Parsed Data Structure: #{parsed_data.keys}"

      # Extract data with more robust parsing
      if parsed_data[:success] && parsed_data[:data]
        @report_data = parsed_data[:data]
        @metadata = parsed_data[:metadata] || {}
      else
        @report_data = parsed_data
        @metadata = {}
      end

      # Additional debugging logs
      Rails.logger.debug "Report Data Keys: #{@report_data.keys}"
      Rails.logger.debug "Metadata Keys: #{@metadata.keys}"

    rescue JSON::ParserError => e
      Rails.logger.error "JSON parsing error: #{e.message}"
      flash[:error] = 'Failed to parse report data'
      redirect_to new_report_path
      return
    rescue StandardError => e
      Rails.logger.error "Unexpected error in show action: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      flash[:error] = 'An unexpected error occurred while loading the report'
      redirect_to new_report_path
      return
    end

    # Check for empty or invalid data
    if @report_data.blank?
      flash[:error] = 'Report data is incomplete'
      redirect_to new_report_path
      return
    end
  end

  private

  def validate_report_params
    required_params = [:start_date, :end_date, :report_type, :detail_level]

    required_params.each do |param|
      if report_params[param].blank?
        flash.now[:error] = "#{param.to_s.humanize} is required"
        render :new and break
      end
    end
  end

  def report_params
    params.permit(
      :start_date,
      :end_date,
      :report_type,
      :detail_level,
      :include_visualizations
    ).transform_keys { |key| key.to_sym }
  end
end

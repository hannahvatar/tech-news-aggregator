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
    # Find the report and log any errors
    @report = Report.find_by(id: params[:id])

    if @report.nil?
      flash[:error] = 'Report not found'
      Rails.logger.error "Report with ID #{params[:id]} not found"
      redirect_to new_report_path
      return
    end

    # Parse the JSON data into a Hash; if parsing fails, default to an empty hash
    parsed_data = JSON.parse(@report.data, symbolize_names: true) rescue {}

    # Safely extract report data and log if it's missing
    @report_data = parsed_data.dig(:data) || {}
    @metadata = parsed_data.dig(:metadata) || {}

    if @report_data.empty? || @metadata.empty?
      flash[:error] = 'Report data is incomplete'
      Rails.logger.warn "Report data or metadata missing for Report ID #{@report.id}"
      redirect_to new_report_path
      return
    end

    Rails.logger.info "Viewing report #{@report.id}"
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

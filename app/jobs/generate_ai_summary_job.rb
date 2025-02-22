class GenerateAiSummaryJob < ApplicationJob
  queue_as :default
  sidekiq_options retry: 3  # Add retry mechanism for Sidekiq

  def perform(article_id, article_type)
    # Extensive logging
    Rails.logger.info "Starting GenerateAiSummaryJob for #{article_type} with ID: #{article_id}"

    # Find the article with more robust error handling
    article = article_type.constantize.find_by(id: article_id)

    if article.nil?
      Rails.logger.error "Article not found: #{article_type} with ID #{article_id}"
      return
    end

    # Log article details
    Rails.logger.info "Article found: #{article.title}"
    Rails.logger.info "Article content length: #{article.content&.length || 'N/A'}"

    # Check for content
    if article.content.blank?
      Rails.logger.error "No content available for article: #{article_type} #{article_id}"
      return
    end

    # Initialize summary service
    summary_service = AiSummaryService.new(article)

    # Generate summary with additional error handling
    begin
      summary_text = summary_service.generate_summary

      # Validate summary
      if summary_text.blank?
        Rails.logger.error "Generated summary is blank for #{article_type} #{article_id}"
        return
      end

      # Begin transaction to ensure atomic operation
      ActiveRecord::Base.transaction do
        # Destroy existing summary
        article.ai_summary&.destroy

        # Create new summary
        new_summary = AiSummary.create!(
          # Dynamically set the correct association based on article type
          article_type.underscore.to_sym => article,
          content: summary_text,
          generated_at: Time.current
        )

        Rails.logger.info "Successfully generated AI summary for #{article_type} #{article_id}"
        Rails.logger.info "Summary length: #{summary_text.length}"
        Rails.logger.info "Summary ID: #{new_summary.id}"
      end
    rescue StandardError => e
      Rails.logger.error "Comprehensive error in summary generation for #{article_type} #{article_id}:"
      Rails.logger.error "Error Class: #{e.class.name}"
      Rails.logger.error "Error Message: #{e.message}"
      Rails.logger.error "Backtrace:\n#{e.backtrace.join("\n")}"

      # Optional: Additional error tracking or notification
      # Rollbar.error(e, article_id: article_id, article_type: article_type) if defined?(Rollbar)

      raise # Re-raise to ensure job failure is recorded
    end
  end
end

class GenerateAiSummaryJob < ApplicationJob
  queue_as :default
  sidekiq_options retry: 3, dead: false  # Add dead job handling

  def perform(article_id, article_type)
    Rails.logger.tagged("GenerateAiSummaryJob", article_type, article_id) do
      Rails.logger.info "Starting job"

      article_class = article_type.safe_constantize
      unless article_class && article_class < ApplicationRecord
        Rails.logger.error "Invalid article type: #{article_type}"
        return
      end

      article = article_class.find_by(id: article_id)
      unless article
        Rails.logger.error "Article not found"
        return
      end

      Rails.logger.info "Processing article: #{article.title}"
      Rails.logger.info "Content length: #{article.content&.length || 'N/A'}"

      if article.content.blank?
        Rails.logger.error "No content available"
        return
      end

      generate_and_save_summary(article)
    end
  end

  private

  def generate_and_save_summary(article)
    summary_service = AiSummaryService.new(article)
    summary_text = summary_service.generate_summary

    if summary_text.blank?
      Rails.logger.error "Generated summary is blank"
      return
    end

    ActiveRecord::Base.transaction do
      article.ai_summary&.destroy
      new_summary = article.create_ai_summary!(
        content: summary_text,
        generated_at: Time.current
      )

      Rails.logger.info "Summary generated successfully"
      Rails.logger.info "Summary length: #{summary_text.length}"
      Rails.logger.info "Summary ID: #{new_summary.id}"
    end
  rescue StandardError => e
    log_error(e)
    raise
  end

  def log_error(error)
    Rails.logger.error "Error in summary generation:"
    Rails.logger.error "Class: #{error.class.name}"
    Rails.logger.error "Message: #{error.message}"
    Rails.logger.error "Backtrace:\n#{error.backtrace.join("\n")}"
    Rollbar.error(error) if defined?(Rollbar)
  end
end

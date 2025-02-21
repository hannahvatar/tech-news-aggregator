# app/jobs/generate_ai_summary_job.rb
class GenerateAiSummaryJob < ApplicationJob
  queue_as :default

  def perform(article_id)
    article = Article.find(article_id)

    Rails.logger.info "Starting AI summary generation for Article #{article_id}"
    Rails.logger.info "Article title: #{article.title}"
    Rails.logger.info "Article content length: #{article.content.length}"
    Rails.logger.info "Article content preview: #{article.content[0..200]}"

    # Destroy existing AI summary if it exists
    if article.ai_summary.present?
      Rails.logger.info "Destroying existing AI summary for Article #{article_id}"
      article.ai_summary.destroy
    end

    # Use the AiSummaryService to generate summary
    summary_service = AiSummaryService.new(article)
    summary_text = summary_service.generate_summary

    Rails.logger.info "Generated summary text length: #{summary_text&.length}"
    Rails.logger.info "Generated summary text preview: #{summary_text&.[](0..200)}"

    if summary_text.blank?
      Rails.logger.error "Failed to generate summary text for Article #{article_id}"
      return nil
    end

    # Create AI Summary
    begin
      ai_summary = AiSummary.create!(
        article: article,
        content: summary_text,
        summarizable: article,
        generated_at: Time.current
      )

      Rails.logger.info "Successfully created AI Summary for Article #{article_id}"
      Rails.logger.info "AI Summary ID: #{ai_summary.id}"
      Rails.logger.info "AI Summary content length: #{ai_summary.content.length}"

      ai_summary
    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.error "Validation failed when creating AI Summary: #{e.record.errors.full_messages}"
      raise
    end
  rescue => e
    Rails.logger.error "Unexpected error in generate_ai_summary_job: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    raise e
  end
end

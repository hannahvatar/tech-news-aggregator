# app/jobs/generate_ai_summary_job.rb
class GenerateAiSummaryJob < ApplicationJob
  queue_as :default

  def perform(article_id)
    # Find the article
    article = Article.find(article_id)

    # Log the start of summary generation
    Rails.logger.info "Generating AI summary for Article #{article_id}: #{article.title}"

    # Use the AiSummaryService to generate summary
    summary_service = AiSummaryService.new(article)
    summary_text = summary_service.generate_summary

    # Remove existing AI summary if present
    article.ai_summary.destroy if article.ai_summary.present?

    # Create new AI summary directly associated with the article
    AiSummary.create!(
      article: article,
      content: summary_text,
      generated_at: Time.current
    )

    # Log successful summary generation
    Rails.logger.info "Successfully generated AI summary for Article #{article_id}"
    Rails.logger.info "Summary: #{summary_text[0..200]}..."

  rescue StandardError => e
    # Detailed error logging
    Rails.logger.error "Failed to generate AI summary for Article #{article_id}: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
  end
end

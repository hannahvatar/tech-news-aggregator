class GenerateAiSummaryJob < ApplicationJob
  queue_as :default

  def perform(article_id)
    article = Article.find(article_id)

    # Log existing AI summary
    Rails.logger.info "Checking existing AI summary for Article #{article_id}"
    Rails.logger.info "Existing AI Summary: #{article.ai_summary.inspect}"

    # Check if AI summary already exists
    return if article.ai_summary.present?

    # Use the AiSummaryService to generate summary
    summary_service = AiSummaryService.new(article)
    summary_text = summary_service.generate_summary

    # Create AI Summary
    ai_summary = AiSummary.create!(
      article: article,
      content: summary_text
    )

    # Log created summary
    Rails.logger.info "Created AI Summary for Article #{article_id}"
    Rails.logger.info "AI Summary Content: #{ai_summary.content}"
  rescue StandardError => e
    Rails.logger.error("Failed to generate AI summary for Article #{article_id}: #{e.message}")
    Rails.logger.error(e.backtrace.join("\n"))
  end
end

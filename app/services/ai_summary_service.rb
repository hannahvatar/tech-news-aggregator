# app/jobs/generate_ai_summaries_job.rb
class GenerateAiSummariesJob < ApplicationJob
  queue_as :default

  def perform(timeframe = 1.week.ago)
    # Log the start of the job
    Rails.logger.info "Starting AI summary generation for articles since #{timeframe}"

    # Find articles without AI summaries
    articles = Article.where('published_at >= ?', timeframe)
                      .left_joins(:ai_summary)
                      .where(ai_summaries: { id: nil })

    Rails.logger.info "Found #{articles.count} articles without summaries"

    # Process each article
    articles.find_each do |article|
      begin
        # Log article details
        Rails.logger.info "Processing article ID: #{article.id}"
        Rails.logger.info "Article title: #{article.title}"

        # Skip if content is blank
        if article.content.blank?
          Rails.logger.warn "Skipping article #{article.id} - no content"
          next
        end

        # Generate summary
        summary_text = AiSummaryService.new(article).generate_summary

        # Create AI Summary
        AiSummary.create!(
          article: article,
          content: summary_text,
          generated_at: Time.current
        )

        Rails.logger.info "Generated summary for article #{article.id}"
      rescue StandardError => e
        Rails.logger.error "Failed to generate summary for article #{article.id}"
        Rails.logger.error "Error: #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
      end
    end
  rescue StandardError => e
    Rails.logger.error "Overall error in AI summary generation"
    Rails.logger.error "Error: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
  end
end

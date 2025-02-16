class GenerateAiSummariesJob < ApplicationJob
  queue_as :default

  def perform(timeframe = nil)
    # Log the start of the job
    Rails.logger.info "=== Starting AI Summary Generation ==="

    # If no timeframe specified, get all articles without summaries
    articles = if timeframe
      Article.where('published_at >= ?', timeframe)
             .where.not(id: AiSummary.select(:article_id))
             .where.not(content: [nil, ''])
    else
      Article.where.not(id: AiSummary.select(:article_id))
             .where.not(content: [nil, ''])
    end

    Rails.logger.info "Total articles without summaries: #{articles.count}"

    # Limit to prevent overwhelming OpenAI API
    articles.limit(50).find_each do |article|
      begin
        # Detailed logging
        Rails.logger.info "Processing Article:"
        Rails.logger.info "ID: #{article.id}"
        Rails.logger.info "Title: #{article.title}"
        Rails.logger.info "Content Length: #{article.content&.length}"

        # Skip if content is too short
        if article.content.to_s.length < 100
          Rails.logger.warn "Skipping article #{article.id} - content too short"
          next
        end

        # Generate summary
        service = AiSummaryService.new(article)
        summary_text = service.generate_summary

        if summary_text.present? && summary_text != "Error generating summary"
          AiSummary.create!(
            article: article,
            content: summary_text,
            generated_at: Time.current
          )
          Rails.logger.info "Successfully generated summary for article #{article.id}"
        else
          Rails.logger.warn "Failed to generate summary for article #{article.id}"
        end

      rescue => e
        Rails.logger.error "Detailed error for article #{article.id}:"
        Rails.logger.error "Error Class: #{e.class}"
        Rails.logger.error "Error Message: #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
      end
    end

  rescue => e
    Rails.logger.error "Overall job error:"
    Rails.logger.error "Error Class: #{e.class}"
    Rails.logger.error "Error Message: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
  end
end

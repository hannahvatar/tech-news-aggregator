# app/services/ai_summary_generator_service.rb
class AiSummaryGeneratorService
  def self.generate_missing_summaries
    # Generate summaries for ScrapedArticles without AI summaries
    scraped_articles_without_summary = ScrapedArticle.left_joins(:ai_summary)
                                        .where(ai_summaries: { id: nil })
                                        .where.not(content: [nil, ''])

    Rails.logger.info "Found #{scraped_articles_without_summary.count} scraped articles without summaries"

    scraped_articles_without_summary.find_each do |article|
      generate_summary_for_article(article)
    end

    # Optionally, do the same for regular Articles if you have them
    articles_without_summary = Article.left_joins(:ai_summary)
                                .where(ai_summaries: { id: nil })
                                .where.not(content: [nil, ''])

    Rails.logger.info "Found #{articles_without_summary.count} articles without summaries"

    articles_without_summary.find_each do |article|
      generate_summary_for_article(article)
    end
  end

  def self.generate_summary_for_article(article)
    Rails.logger.info "Generating summary for #{article.class.name} #{article.id}"

    begin
      summary_service = AiSummaryService.new(article)
      summary_text = summary_service.generate_summary

      AiSummary.create!(
        (article.is_a?(ScrapedArticle) ? :scraped_article : :article) => article,
        content: summary_text,
        generated_at: Time.current
      )

      Rails.logger.info "Successfully generated summary for #{article.class.name} #{article.id}"
    rescue => e
      Rails.logger.error "Failed to generate summary for #{article.class.name} #{article.id}: #{e.message}"
    end
  end
end

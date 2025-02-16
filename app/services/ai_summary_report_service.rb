# app/services/ai_summary_report_service.rb
class AiSummaryReportService
  def initialize(timeframe = 1.week.ago)
    @timeframe = timeframe
  end

  def generate_report
    articles = Article.joins(:ai_summary)
                      .where('articles.published_at >= ?', @timeframe)
                      .order(published_at: :desc)

    # Group summaries by feed or category
    summaries_by_feed = articles.group_by { |article| article.feed.name }

    # Generate a comprehensive report
    report = "AI-Generated Article Summary Report\n"
    report += "Generated at: #{Time.current}\n"
    report += "Covering articles from: #{@timeframe}\n\n"

    summaries_by_feed.each do |feed_name, articles|
      report += "=== #{feed_name} ===\n"
      articles.each do |article|
        report += "- #{article.title}\n"
        report += "  Published: #{article.published_at.strftime('%B %d, %Y')}\n"
        report += "  Summary: #{article.ai_summary.content}\n\n"
      end
    end

    report
  end

  def save_report
    report_content = generate_report
    filename = "ai_summary_report_#{Time.current.to_i}.txt"

    File.write(Rails.root.join('tmp', filename), report_content)
    filename
  end
end

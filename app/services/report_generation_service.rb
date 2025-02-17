# app/services/report_generation_service.rb
class ReportGenerationService
  def initialize(params)
    @params = params.with_indifferent_access
    validate_params!
  end

  def generate
    Rails.logger.debug "Starting report generation with params: #{@params.inspect}"

    start_date = parse_date(:start_date)
    end_date = parse_date(:end_date)

    Rails.logger.debug "Fetching articles between #{start_date} and #{end_date}"
    articles = fetch_articles(start_date, end_date)

    if articles.empty?
      Rails.logger.debug "No articles found for the date range"
      return {
        error: 'No articles found for the selected date range',
        success: false
      }
    end

    Rails.logger.debug "Found #{articles.count} articles"
    process_articles(articles)
  rescue StandardError => e
    Rails.logger.error "Report generation failed: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    {
      error: "Failed to generate report: #{e.message}",
      success: false
    }
  end

  private

  def validate_params!
    # Check for required parameters
    required_params = [:start_date, :end_date, :report_type, :detail_level]
    missing_params = required_params.select { |param| @params[param].blank? }

    raise ArgumentError, "Missing required parameters: #{missing_params.join(', ')}" if missing_params.any?
  end

  def parse_date(date_param)
    date_str = @params[date_param]
    raise ArgumentError, "Invalid #{date_param}" if date_str.blank?

    Date.parse(date_str)
  rescue ArgumentError
    raise ArgumentError, "Invalid date format for #{date_param}. Use YYYY-MM-DD format."
  end

  def fetch_articles(start_date, end_date)
    Article.includes(:feed, :ai_summary, :tags)
          .where(published_at: start_date.beginning_of_day..end_date.end_of_day)
          .order(published_at: :desc)
  end

  def process_articles(articles)
    Rails.logger.debug "Processing #{articles.count} articles"

    report_data = {
      executive_summary: generate_executive_summary(articles),
      key_trends: analyze_trends(articles),
      recommendations: generate_recommendations(articles)
    }

    Rails.logger.debug "Generated report data: #{report_data.inspect}"

    {
      success: true,
      data: report_data,
      metadata: {
        article_count: articles.count,
        date_range: "#{@params[:start_date]} to #{@params[:end_date]}",
        report_type: @params[:report_type],
        detail_level: @params[:detail_level]
      }
    }
  end

  def generate_executive_summary(articles)
    feeds_summary = articles.group_by(&:feed).transform_values(&:count)
    recent_articles = articles.first(5)

    summary = "Tech Insights Report: Analysis of #{articles.count} articles published between #{@params[:start_date]} and #{@params[:end_date]}, " \
              "covering #{feeds_summary.count} different tech news sources.\n\n"

    summary += "Key Highlights:\n"
    recent_articles.each do |article|
      summary += "- #{article.title}"
      if article.ai_summary&.content.present?
        summary += "\n  Summary: #{article.ai_summary.content}"
      end
      summary += "\n"
    end

    summary
  end

  def analyze_trends(articles)
    trends = []

    # Source Distribution
    source_distribution = articles.group_by(&:feed)
                                  .transform_values(&:count)
                                  .sort_by { |_, count| -count }
                                  .first(5)
                                  .to_h

    trends << {
      title: "News Source Distribution",
      description: "Top sources by article count",
      data: source_distribution
    }

    # Tag Analysis
    tag_counts = articles.flat_map(&:tags)
                         .group_by(&:name)
                         .transform_values(&:count)
                         .sort_by { |_, count| -count }
                         .first(5)
                         .to_h

    trends << {
      title: "Topic Distribution",
      description: "Most frequent topics across articles",
      data: tag_counts
    }

    # Temporal Analysis
    days_of_week = articles.group_by { |a| a.published_at.strftime('%A') }
                           .transform_values(&:count)
                           .sort_by { |_, count| -count }
                           .to_h

    trends << {
      title: "Publication Timing",
      description: "Articles by day of the week",
      data: days_of_week
    }

    trends
  end

  def generate_recommendations(articles)
    source_distribution = articles.group_by(&:feed)
                                  .transform_values(&:count)
                                  .sort_by { |_, count| -count }

    tag_counts = articles.flat_map(&:tags)
                         .group_by(&:name)
                         .transform_values(&:count)

    recommendations = [
      {
        title: "Top News Sources",
        impact_level: "High",
        timeline: "Ongoing",
        description: "Focus on top sources: #{source_distribution.first(3).map { |feed, count| "#{feed.name} (#{count} articles)" }.join(', ')}"
      },
      {
        title: "Key Topic Focus",
        impact_level: "Medium",
        timeline: "Short-term",
        description: "Trending topics: #{tag_counts.sort_by { |_, count| -count }.first(5).map { |tag, count| "#{tag} (#{count} mentions)" }.join(', ')}"
      },
      {
        title: "Publication Strategy",
        impact_level: "Low",
        timeline: "Medium-term",
        description: "Most active publication days: #{source_distribution.first(3).map { |feed, _| feed.name }.join(', ')}"
      }
    ]

    recommendations
  end
end

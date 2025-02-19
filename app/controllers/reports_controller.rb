class ReportsController < ApplicationController
  def new
    @report = Report.new
  end

  def generate
    @report = Report.new(report_params)
    start_date = params[:start_date]
    end_date = params[:end_date]
    articles = fetch_articles(start_date, end_date)

    @report.data = {
      metadata: {
        status: 'initializing',
        date_range: "#{start_date} - #{end_date}",
        article_count: articles.length,
        articles: articles,
        generated_at: Time.current
      }
    }

    @report.start_date = start_date
    @report.end_date = end_date

    if @report.save
      client = OpenAI::Client.new(access_token: ENV['OPENAI_API_KEY'])

      begin
        # First, get a high-level outline
        structure_response = client.chat(
          parameters: {
            model: "gpt-3.5-turbo-16k",  # Using 16k model for larger context
            messages: [
              {
                role: "system",
                content: "You are a senior technology analyst creating in-depth trend reports focusing on UX and design trends. Focus on concrete examples and actionable insights."
              },
              {
                role: "user",
                content: "Create a detailed outline for a comprehensive UX and technology trends analysis report based on analyzing these articles: #{articles.map{|a| "#{a[:title]} from #{a[:source]}"}.join(', ')}. The report should cover:\n1. Executive Summary\n2. Detailed Analysis of Each Major UX/Design Trend\n3. Technical Deep Dives\n4. Market Impact Analysis\n5. Future Predictions\n6. Industry Applications\n7. Challenges and Opportunities\n8. Implementation Strategies"
              }
            ],
            temperature: 0.7,
            max_tokens: 2000
          }
        )

        outline = structure_response.dig('choices', 0, 'message', 'content')

        # Define report sections with larger token allocations
        sections = [
          { title: "Executive Summary and Overview", tokens: 2000 },
          { title: "Technical Analysis and Deep Dives", tokens: 3000 },
          { title: "Market Impact and Industry Applications", tokens: 3000 },
          { title: "Implementation Strategies and Best Practices", tokens: 3000 },
          { title: "Future Trends and Predictions", tokens: 3000 },
          { title: "Challenges, Opportunities, and Recommendations", tokens: 2000 }
        ]

        full_report = []

        # Generate each section with more detailed prompting
        sections.each do |section|
          section_response = client.chat(
            parameters: {
              model: "gpt-3.5-turbo-16k",  # Using 16k model for larger context
              messages: [
                {
                  role: "system",
                  content: "You are a senior UX and technology analyst writing a detailed section of a comprehensive trend report. Focus on concrete examples, data-driven insights, and actionable recommendations. Use markdown formatting for better readability."
                },
                {
                  role: "user",
                  content: "Based on analyzing these articles from #{start_date} to #{end_date}: #{articles.map{|a| "#{a[:title]} (#{a[:source]})"}.join(', ')}, generate the '#{section[:title]}' section of the report. This should be approximately #{section[:tokens]/2} words with concrete examples and insights. Use the following outline as context: #{outline}\n\nEnsure your response is well-structured with clear headings and subheadings using markdown format."
                }
              ],
              temperature: 0.7,
              max_tokens: section[:tokens]
            }
          )

          full_report << "## #{section[:title]}\n\n"
          full_report << section_response.dig('choices', 0, 'message', 'content')
          full_report << "\n\n"

          # Add delay to respect rate limits
          sleep(1)
        end

        if full_report.any?
          @report.data = {
            analysis: full_report.join,
            metadata: {
              date_range: "#{start_date} - #{end_date}",
              article_count: articles.length,
              articles: articles,
              status: 'completed',
              generated_at: Time.current,
              report_type: 'comprehensive',
              word_count: full_report.join.split.size,
              sections: sections.map { |s| s[:title] }
            }
          }

          if @report.save
            redirect_to @report, notice: 'Comprehensive report generated successfully!'
          else
            redirect_to new_report_path, alert: 'Failed to save report content.'
          end
        else
          redirect_to new_report_path, alert: 'Failed to generate report content.'
        end
      rescue => e
        Rails.logger.error("OpenAI Error: #{e.message}")
        redirect_to new_report_path, alert: 'Error generating report. Please try again.'
      end
    else
      render :new
    end
  end

  def show
    @report = Report.find(params[:id])

    Rails.logger.debug "Report ID: #{@report.id}"
    Rails.logger.debug "Report start_date: #{@report.start_date}"
    Rails.logger.debug "Report end_date: #{@report.end_date}"
    Rails.logger.debug "Report data: #{@report.data.inspect}"
  rescue ActiveRecord::RecordNotFound
    flash[:alert] = "Report not found"
    redirect_to new_report_path
  end

  private

  def fetch_articles(start_date, end_date)
    start_date = Date.parse(start_date)
    end_date = Date.parse(end_date)

    Article.joins(:feed)
           .where(published_at: start_date.beginning_of_day..end_date.end_of_day)
           .map do |article|
      {
        title: article.title,
        url: article.url,
        source: article.feed.name,
        published_at: article.published_at
      }
    end
  end

  def report_params
    params.permit(:start_date, :end_date)
  end
end

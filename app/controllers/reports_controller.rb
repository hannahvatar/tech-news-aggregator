# app/controllers/reports_controller.rb
class ReportsController < ApplicationController
 def new
   @report = Report.new
 end

 def generate
   @report = Report.new(report_params)

   # Use the provided start and end dates from params
   start_date = params[:start_date]
   end_date = params[:end_date]

   # Fetch articles (replace with your actual article fetching logic)
   articles = fetch_articles(start_date, end_date)

   # Setup initial data structure
   @report.data = {
     metadata: {
       status: 'initializing',
       date_range: "#{start_date} - #{end_date}",
       article_count: articles.length,
       articles: articles  # Include full article details
     }
   }

   # Explicitly set start_date and end_date
   @report.start_date = start_date
   @report.end_date = end_date

   if @report.save
     # Setup OpenAI client
     client = OpenAI::Client.new(access_token: ENV['OPENAI_API_KEY'])

     begin
       response = client.chat(
         parameters: {
           model: "gpt-3.5-turbo",
           messages: [
             {
               role: "system",
               content: "You are a technology analyst creating comprehensive trend reports."
             },
             {
               role: "user",
               content: "Generate a comprehensive technology trends analysis report based on these articles: #{articles.map{|a| a[:title]}.join(', ')}. The report should be around 2,000 words and include: \n1. Executive Summary\n2. Key Technology Trends\n3. Impact Analysis\n4. Future Implications"
             }
           ],
           temperature: 0.7,
           max_tokens: 2048
         }
       )

       if response.dig('choices', 0, 'message', 'content')
         @report.data = {
           analysis: response['choices'][0]['message']['content'],
           metadata: {
             date_range: "#{start_date} - #{end_date}",
             article_count: articles.length,
             articles: articles,  # Preserve article details
             status: 'completed',
             generated_at: Time.current
           }
         }

         if @report.save
           redirect_to @report, notice: 'Report generated successfully!'
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

   # Debug logging
   Rails.logger.debug "Report ID: #{@report.id}"
   Rails.logger.debug "Report start_date: #{@report.start_date}"
   Rails.logger.debug "Report end_date: #{@report.end_date}"
   Rails.logger.debug "Report data: #{@report.data.inspect}"
   Rails.logger.debug "Report metadata: #{@report.metadata.inspect}"
 rescue ActiveRecord::RecordNotFound
   flash[:alert] = "Report not found"
   redirect_to new_report_path
 end

 private

 def fetch_articles(start_date, end_date)
  start_date = Date.parse(start_date)
  end_date = Date.parse(end_date)

  # Get all articles from feeds within the date range
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

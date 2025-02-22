# app/services/ai_summary_service.rb
class AiSummaryService
  def initialize(article)
    @article = article

    # Initialize OpenAI client
    begin
      api_key = Rails.application.credentials.dig(:openai, :api_key)
      @client = OpenAI::Client.new(
        access_token: api_key,
        request_timeout: 30
      )
    rescue => e
      Rails.logger.error "Error initializing OpenAI client: #{e.message}"
      raise e
    end
  end

  def generate_summary
    # Prepare article content
    content = prepare_content

    # Log content details for debugging
    Rails.logger.info "Generating summary for article #{@article.id}"
    Rails.logger.info "Prepared content length: #{content.length}"

    # Make OpenAI API call
    response = @client.chat(
      parameters: {
        model: "gpt-3.5-turbo",
        messages: [
          {
            role: "system",
            content: "You are an expert content summarizer. Create a concise, informative summary that captures the key points of the article."
          },
          {
            role: "user",
            content: "Summarize the following article, focusing on the main ideas and key insights:\n\n#{content}"
          }
        ],
        temperature: 0.7,
        max_tokens: 1000
      }
    )

    # Extract and return summary
    if response["choices"] && response["choices"][0]["message"]["content"]
      summary = response["choices"][0]["message"]["content"].strip
      Rails.logger.info "Generated summary for Article #{@article.id}"
      summary
    else
      Rails.logger.error "Invalid response format for Article #{@article.id}"
      "Unable to generate summary"
    end
  rescue => e
    Rails.logger.error "Error generating summary for Article #{@article.id}: #{e.message}"
    "Error generating summary: #{e.message}"
  end

  private

  def prepare_content
    return "" if @article.content.blank?

    # Clean and prepare article content
    content = @article.content.to_s

    # Remove HTML tags
    content = ActionView::Base.full_sanitizer.sanitize(content)

    # Clean up the text
    content = content.strip
               .gsub(/\s+/, ' ')
               .gsub(/\[.*?\]/, '')
               .gsub(/Read more at.*/, '')

    # Truncate to prevent overwhelming the API
    content.truncate(4000, separator: ' ', omission: '...')
  end
end

# app/services/ai_summary_service.rb
class AiSummaryService
  def initialize(article)
    @article = article

    # Initialize OpenAI client
    begin
      api_key = Rails.application.credentials.dig(:openai, :api_key)
      raise "OpenAI API key not found" if api_key.blank?

      @client = OpenAI::Client.new(
        access_token: api_key,
        request_timeout: 30
      )
    rescue => e
      Rails.logger.error "Error initializing OpenAI client: #{e.message}"
      raise
    end
  end

  def generate_summary
    # Prepare article content
    content = prepare_content

    # Validate content
    if content.blank?
      Rails.logger.warn "No content available for summary generation for Article #{@article.id}"
      return "No content available for summary"
    end

    # Log content details for debugging
    Rails.logger.info "Generating summary for article #{@article.id}"
    Rails.logger.info "Prepared content length: #{content.length}"

    # Make OpenAI API call
    begin
      response = @client.chat(
        parameters: {
          model: "gpt-3.5-turbo",
          messages: [
            {
              role: "system",
              content: "You are an expert content summarizer. Create an informative summary of about 150 words that captures the key points of the article."
            },
            {
              role: "user",
              content: "Summarize the following article in about 150 words, focusing on the main ideas and key insights:\n\n#{content}"
            }
          ],
          temperature: 0.7,
          max_tokens: 400
        }
      )

      # Extract and validate summary
      if response.dig("choices", 0, "message", "content")
        summary = response["choices"][0]["message"]["content"].strip

        # Additional validation
        if summary.length < 50
          Rails.logger.warn "Generated summary too short for Article #{@article.id}"
          return "Unable to generate a meaningful summary"
        end

        Rails.logger.info "Generated summary for Article #{@article.id}"
        Rails.logger.info "Summary length: #{summary.length}"

        summary
      else
        Rails.logger.error "Invalid response format for Article #{@article.id}"
        "Unable to generate summary"
      end
    rescue OpenAI::Error => e
      Rails.logger.error "OpenAI API error for Article #{@article.id}: #{e.message}"
      "Error generating summary: API request failed"
    rescue StandardError => e
      Rails.logger.error "Unexpected error generating summary for Article #{@article.id}: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      "Error generating summary: #{e.message}"
    end
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
               .gsub(/https?:\/\/\S+/, '')  # Remove URLs

    # Truncate to prevent overwhelming the API
    truncated_content = content.truncate(4000, separator: ' ', omission: '...')

    # Log truncation info
    Rails.logger.info "Content truncated from #{content.length} to #{truncated_content.length} characters"

    truncated_content
  end
end

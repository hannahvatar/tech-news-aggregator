# app/services/ai_summary_service.rb
class AiSummaryService
  def initialize(article)
    @article = article
    Rails.logger.info "=== AiSummaryService Debug ==="
    Rails.logger.info "Article ID: #{article.id}"
    Rails.logger.info "Article Title: #{article.title}"

    begin
      api_key = Rails.application.credentials.dig(:openai, :api_key)
      Rails.logger.info "OpenAI API Key present?: #{!api_key.nil?}"
      Rails.logger.info "OpenAI API Key length: #{api_key&.length}"

      @client = OpenAI::Client.new(
        access_token: api_key,
        request_timeout: 30
      )
      Rails.logger.info "OpenAI client initialized successfully"
    rescue => e
      Rails.logger.error "Error initializing OpenAI client: #{e.message}"
      raise e
    end
  end

  def generate_summary
    Rails.logger.info "Generating summary for article #{@article.id}"
    begin
      content = prepare_content
      Rails.logger.info "Prepared content length: #{content.length}"
      Rails.logger.info "Content sample: #{content[0..200]}"

      response = @client.chat(
        parameters: {
          model: "gpt-3.5-turbo",
          messages: [
            {
              role: "system",
              content: "You are an expert content analyst. Create a concise summary without repeating the title."
            },
            {
              role: "user",
              content: "Create a 2-3 paragraph summary of this article: #{content}"
            }
          ],
          temperature: 0.7,
          max_tokens: 500
        }
      )

      Rails.logger.info "OpenAI Response: #{response.inspect}"

      if response["choices"] && response["choices"][0]["message"]["content"]
        summary = response["choices"][0]["message"]["content"].strip
        Rails.logger.info "Generated summary: #{summary}"
        summary
      else
        Rails.logger.error "Invalid response format: #{response.inspect}"
        "Error generating summary"
      end
    rescue => e
      Rails.logger.error "Error in generate_summary: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      "Error: #{e.message}"
    end
  end

  private

  def prepare_content
    return "" if @article.content.blank?

    content = @article.content.to_s

    # Remove HTML tags
    content = ActionView::Base.full_sanitizer.sanitize(content)

    # Clean up the text
    content = content.strip
               .gsub(/\s+/, ' ')
               .gsub(/\[.*?\]/, '')
               .gsub(/Read more at.*/, '')

    content.truncate(4000, separator: ' ', omission: '...')
  end
end

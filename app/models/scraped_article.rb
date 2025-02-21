class ScrapedArticle < ApplicationRecord
  belongs_to :scraped_feed # This sets up the association with ScrapedFeed
  belongs_to :article

  has_one :ai_summary, as: :summarizable

  after_create :generate_ai_summary

  private

  def generate_ai_summary
    summary = fetch_openai_summary(self.content)
    self.create_ai_summary(content: summary)
  end

  def fetch_openai_summary(content)
    openai_api_key = "your-api-key-here"
    response = HTTParty.post(
      "https://api.openai.com/v1/completions",
      body: {
        model: "text-davinci-003",
        prompt: "Summarize the following article:\n\n#{content}",
        max_tokens: 150
      }.to_json,
      headers: { "Authorization" => "Bearer #{openai_api_key}", "Content-Type" => "application/json" }
    )

    response["choices"][0]["text"].strip
  end
end

# app/jobs/generate_all_ai_summaries_job.rb
class GenerateAllAiSummariesJob < ApplicationJob
  queue_as :default

  def perform
    Article.find_each do |article|
      GenerateAiSummaryJob.perform_later(article.id)
    end
  end
end

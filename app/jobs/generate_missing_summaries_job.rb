# app/jobs/generate_missing_summaries_job.rb
class GenerateMissingSummariesJob < ApplicationJob
  queue_as :default

  def perform
    AiSummaryGeneratorService.generate_missing_summaries
  end
end

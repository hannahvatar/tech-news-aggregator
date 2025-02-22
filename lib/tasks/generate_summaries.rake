namespace :summaries do
  desc "Generate AI summaries for articles without summaries"
  task generate: :environment do
    AiSummaryGeneratorService.generate_missing_summaries
  end
end

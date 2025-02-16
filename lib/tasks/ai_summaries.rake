# lib/tasks/ai_summaries.rake
namespace :ai_summaries do
  desc "Generate AI summaries for recent articles"
  task generate: :environment do
    GenerateAiSummariesJob.perform_now
  end

  desc "Generate AI summaries for articles in the last week"
  task generate_weekly: :environment do
    GenerateAiSummariesJob.perform_now(1.week.ago)
  end
end

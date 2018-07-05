require_relative "../utils/socrata_client"
require_relative "../utils/exec_summary"

# Usage:
#
#  - Updates execution and total execution for Gencat municipalities with the changes since the specified date.
#    You should update total budgets in the next step of the pipeline.
#  - Must be ran as a rails runner from gobierto-budgets-comparator or gobierto-budgets-comparator-gen-cat
#
# Arguments:
#
#  - 0: Date from the one the changes will be retrieved, defaults to 2 days ago
#
# Samples:
#
#  cd .../gobierto-budgets-comparator-gen-cat || cd .../gobierto-budgets-comparator
#  bin/rails runner .../populate-data-indicators/private_data/gobierto_budgets_comparator/gencat/update_execution.rb 2017-03-15
#
#  For faster imports in development: FAST_RUN=true bin/rails runner ...
#

DEBUG = Rails.env.development? || Rails.env.staging?
UPDATED_SINCE = if ARGV[0]
                  Time.zone.parse ARGV[0]
                else
                  2.days.ago
                end

exec_summary = ExecSummary.new

puts "[START] gobierto_budgets_comparator/gencat/update_execution.rb  updated_since: #{UPDATED_SINCE}"
puts "[!] Running with fast run" if (ENV["FAST_RUN"] == "true")

client = SocrataClient.new

# ordering via API does not work
available_years = (UPDATED_SINCE.year..Time.zone.now.year).to_a.reverse

available_years.each do |exercise_year|
  puts "[INFO] Requesting updates since #{UPDATED_SINCE} for year #{exercise_year}"

  client.update_execution!(UPDATED_SINCE, exec_summary, exercise_year)
end

exec_summary.finalize_summary

File.open("scanned_organizations_ids.update_execution.txt", "w+") do |file|
  file.write exec_summary.scanned_organizations_ids.join("\n")
end

puts "[END] gobierto_budgets_comparator/gencat/update_execution.rb"

exit exec_summary.success?

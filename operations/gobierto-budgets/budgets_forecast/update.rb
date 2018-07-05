require_relative "../utils/socrata_client"
require_relative "../utils/exec_summary"

# Usage:
#
#  - Updates forecast and total budgets for Gencat municipalities with the changes since the specified date.
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
#  bin/rails runner .../populate-data-indicators/private_data/gobierto_budgets_comparator/gencat/update.rb 2017-03-15
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

MAX_TRIES = 10
tries = 0

puts "[START] gobierto_budgets_comparator/gencat/update.rb  updated_since: #{UPDATED_SINCE}"
puts "[!] Running with fast run" if (ENV["FAST_RUN"] == "true")

begin
  puts "Starting try \##{tries + 1}"

  client = SocrataClient.new

  client.update_budget_lines!(UPDATED_SINCE, exec_summary, DEBUG)
rescue StandardError
  puts $!
  tries += 1
  if tries < MAX_TRIES
    sleep 60
    retry
  end
  puts "\nExiting after #{tries} re-tries.....\n"
ensure
  exec_summary.finalize_summary
  exec_summary.print

  File.open("imported_organizations_ids.update.txt", "w+") do |file|
    file.write exec_summary.imported_organizations_ids.join("\n")
  end

  File.open("scanned_organizations_ids.update.txt", "w+") do |file|
    file.write exec_summary.scanned_organizations_ids.join("\n")
  end

  puts "[END] gobierto_budgets_comparator/gencat/update.rb"

  exit exec_summary.success?
end

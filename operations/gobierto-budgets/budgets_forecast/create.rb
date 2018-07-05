# Usage:
#
#  - Creates all forecast data for Gencat municipalities, for the specified years.
#    You should create total budgets in the following step of the pipeline.
#  - Must be ran as a rails runner from gobierto-budgets-comparator or gobierto-budgets-comparator-gen-cat
#
# Arguments:
#
#  - 0: Years to import forecast, defaults to 2010..current_year
#
# Samples:
#
#  cd .../gobierto-budgets-comparator-gen-cat || cd .../gobierto-budgets-comparator
#  bin/rails runner .../populate-data-indicators/private_data/gobierto_budgets_comparator/gencat/create.rb
#  bin/rails runner .../populate-data-indicators/private_data/gobierto_budgets_comparator/gencat/create.rb "2010 2016 2017"
#
#  For faster imports in development: FAST_RUN=true bin/rails runner ...
#

require_relative "../utils/socrata_client"
require_relative "../utils/exec_summary"

DEBUG = Rails.env.development?

years_arg = ARGV[0]
all_years = (2010..Time.zone.now.year).to_a

YEARS = years_arg ? years_arg.split.map(&:to_i) : all_years

exec_summary = ExecSummary.new

MAX_TRIES = 10
tries = 0

puts "[START] gobierto_budgets_comparator/gencat/create.rb"
puts "[!] Running with fast run" if (ENV["FAST_RUN"] == "true")

begin
  puts "Starting try \##{tries + 1}"

  client = SocrataClient.new

  YEARS.each do |year|
    puts "Importing budgets forecast for year #{year}"
    client.create_budget_lines!(year, exec_summary, DEBUG)
  end
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

  File.open("imported_organizations_ids.create.txt", "w+") do |file|
    file.write exec_summary.imported_organizations_ids.join("\n")
  end

  File.open("scanned_organizations_ids.create.txt", "w+") do |file|
    file.write exec_summary.scanned_organizations_ids.join("\n")
  end

  puts "[END] gobierto_budgets_comparator/gencat/create.rb"

  exit exec_summary.success?
end

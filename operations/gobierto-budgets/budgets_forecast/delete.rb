# Usage:
#
#  - Deletes all forecast data for Gencat municipalities. You should delete total budgets in the following
#    step of the pipeline.
#  - Must be ran as a rails runner from gobierto-budgets-comparator or gobierto-budgets-comparator-gen-cat
#
# Samples:
#
#  cd .../gobierto-budgets-comparator-gen-cat || cd .../gobierto-budgets-comparator
#  bin/rails runner .../populate-data-indicators/private_data/gobierto_budgets_comparator/gencat/delete.rb
#

require_relative "../utils/configuration"

puts "[START] gobierto_budgets_comparator/gencat/delete.rb"

ES_INDEX = GobiertoBudgets::SearchEngineConfiguration::BudgetLine.index_forecast
ES_TYPES = [
  ::GobiertoData::GobiertoBudgets::ECONOMIC_BUDGET_TYPE,
  ::GobiertoData::GobiertoBudgets::FUNCTIONAL_BUDGET_TYPE
]

catalunya  = INE::Places::AutonomousRegion.find_by_slug("catalunya")
places_ids = catalunya.provinces.map { |province| province.places }.flatten.map { |place| place.id }

deletable_places_ids = places_ids - EXCLUDED_PLACES_IDS

deletable_organizations_ids = ::GobiertoBudgets::AssociatedEntity.where(
                                ine_code: places_ids.map(&:to_i)
                              ).pluck(:entity_id)

puts "Will delete data in #{ES_INDEX} index, #{ES_TYPES} types for the following places:"
puts deletable_places_ids.each { |id| puts id }
puts "Will delete data in #{ES_INDEX} index, #{ES_TYPES} types for the following organizations:"
puts deletable_organizations_ids.each { |id| puts id }

body = {
  query: {
    bool: {
      should: [
        { terms: { ine_code: deletable_places_ids } },
        { terms: { organization_id: deletable_organizations_ids } }
      ]
    }
  },
  size: 100_000
}

puts "Searching for first bulk..."

response = ES_CLIENT.search(index: ES_INDEX, body: body)

bulk_operations = response["hits"]["hits"].map do |hit|
  { delete: { _index: ES_INDEX, _type: hit["_type"], _id: hit["_id"] } }
end

puts "Search completed"

while bulk_operations.any? do
  puts "Running bulk of delete operations..."

  ES_CLIENT.bulk(body: bulk_operations, refresh: true)

  puts "Bulk operations completed. Searching for next bulk..."

  response = ES_CLIENT.search(index: ES_INDEX, body: body)

  bulk_operations = response["hits"]["hits"].map do |hit|
    { delete: { _index: ES_INDEX, _type: hit["_type"], _id: hit["_id"] } }
  end

  puts "Search completed"
end

puts "[END] gobierto_budgets_comparator/gencat/delete.rb"

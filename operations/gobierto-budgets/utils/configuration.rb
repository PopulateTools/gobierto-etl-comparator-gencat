require "gobierto_data"

EXCLUDED_PLACES_IDS = [
  INE::Places::Place.find_by_slug("mataro").id,
  INE::Places::Place.find_by_slug("esplugues-de-llobregat").id
]

ES_CLIENT = GobiertoData::GobiertoBudgets::SearchEngine.client

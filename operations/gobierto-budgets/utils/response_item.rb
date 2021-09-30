require_relative "configuration"
require_relative "record_parser"

class ResponseItem

  ES_INDEX = GobiertoBudgetsData::GobiertoBudgets::ES_INDEX_FORECAST

  class MissingAmount < StandardError; end
  class MissingPopulation < StandardError; end
  class InvalidCode < StandardError; end
  class ExcludedPlace < StandardError; end

  attr_reader(
    :response_data,
    :name,
    :entity,
    :year,
    :kind,
    :area,
    :code,
    :level,
    :amount,
    :description,
    :parent_code,
    :place,
    :autonomous_region,
    :population,
    :id
  )

  def initialize(response_data)
    rd = response_data
    @client = GobiertoBudgetsData::GobiertoBudgets::SearchEngineWriting.client

    @response_data = rd
    @name = rd.nom_complert
    @entity = rd.codi_ens
    @year = RecordParser.parse_year(rd)
    @kind = RecordParser.parse_kind(rd)
    @area = RecordParser.parse_area(rd)
    @code = RecordParser.parse_code(rd)
    @level = RecordParser.calculate_level(code)
    @parent_code = RecordParser.calculate_parent_code(code, level)
    @amount = rd.import.to_f
    @description = rd.descripcio
    @place = INE::Places::Place.find(entity[0..-6])
    @autonomous_region = INE::Places::AutonomousRegion.find_by_slug("catalunya")
    @id = [organization_id, year, code, kind].join("/")
    set_population unless not_associated_to_municipality?
  end

  def validate!
    raise MissingAmount if amount.nil? || amount == 0
    raise InvalidCode if code.length != 6 && code.length != level
    raise MissingPopulation if associated_to_municipality? && population.nil?
    raise ExcludedPlace if ine_code && EXCLUDED_PLACES_IDS.include?(ine_code)
  end

  def city_council?
    name.downcase.starts_with?('ajun')
  end

  def associated_to_municipality?
    place.present?
  end

  # associated to autonomous community, 'comarca', etc.
  def not_associated_to_municipality?
    !associated_to_municipality?
  end

  def place_id
    place.id.to_i
  end

  def ine_code
    place_id if city_council?
  end

  def associated_entity_name
    name unless city_council?
  end

  def outdated?
    amount != stored_doc["amount"].to_f ||
    (stored_doc["amount_per_inhabitant"] && amount_per_inhabitant != stored_doc["amount_per_inhabitant"].to_f)
  end

  def create!
    @client.index(
      index: ES_INDEX,
      type: area,
      id: id,
      body: attributes_for_creating
    )
  end

  def update!
    @client.index(
      index: ES_INDEX,
      type: area,
      id: id,
      body: stored_doc.merge(attributes_for_updating)
    )
  end

  def entity_id
    entity
  end

  def organization_id
    if city_council?
      ine_code.to_s
    elsif associated_to_municipality?
      "#{place_id}-gencat-#{entity_id}"
    else
      "#{autonomous_region_id}-gencat-#{entity_id}"
    end
  end

  def attributes_for_associated_entity
    {
      entity_id: organization_id,
      name: name,
      ine_code: associated_to_municipality? ? place_id : autonomous_region_id
    }
  end

  private

  def get_population(year)
    response = @client.get(
      index: "data",
      type: "population",
      id: "#{place_id}/#{year}"
    )
    response['_source']['value']
  rescue
    nil
  end

  def province_id
    place.province.id.to_i unless not_associated_to_municipality?
  end

  def autonomous_region_id
    autonomous_region.id.to_i
  end

  def amount_per_inhabitant
    (amount.to_f / population).round(2) if amount
  end

  def rounded_amount
    amount.to_f.round(2) if amount
  end

  def attributes_for_creating
    base_attributes = {
      organization_id: organization_id,
      year: year,
      amount: rounded_amount,
      code: code,
      level: level,
      kind: kind,
      parent_code: parent_code
    }

    base_attributes.merge!(
      ine_code: ine_code,
      province_id: province_id,
      autonomy_id: autonomous_region_id
    ) if city_council?

    base_attributes.merge!(
      amount_per_inhabitant: amount_per_inhabitant,
      population: population
    ) unless not_associated_to_municipality?

    base_attributes
  end

  def attributes_for_updating
    if associated_to_municipality?
      { amount: amount, amount_per_inhabitant: amount_per_inhabitant }
    else
      { amount: amount }
    end
  end

  def stored_doc
    @stored_doc ||= @client.get(index: ES_INDEX, type: area, id: id)["_source"]
  end

  def set_population
    @population = get_population(year) || get_population(year - 1) || get_population(year - 2)
  end

end

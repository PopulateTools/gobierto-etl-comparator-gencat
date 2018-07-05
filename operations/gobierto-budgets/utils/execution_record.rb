require_relative "record_parser"

class ExecutionRecord

  include ActiveModel::Model

  ES_INDEX  = ::GobiertoData::GobiertoBudgets::ES_INDEX_EXECUTED
  ES_CLIENT = GobiertoData::GobiertoBudgets::SearchEngine.client

  attr_accessor(
    :response_item,
    :name,
    :description,
    :kind,
    :area,
    :code,
    :level,
    :year,
    :external_entity_code,
    :executed_amount
  )

  attr_reader(
    :organization_id,
    :parent_code,
    :executed_amount_per_inhabitant,
    :population,
    :municipality
  )

  def initialize(response_item)
    @response_item = response_item
    super(parsed_attributes)
    set_organization_id
    @level = RecordParser.calculate_level(code)
    @parent_code = RecordParser.calculate_parent_code(code, level)
    set_population if city_council? || entity_depends_on_municipality?
    set_executed_amount_per_inhabitant if city_council? || entity_depends_on_municipality?
  end

  def city_council?
    name.downcase.starts_with?("ajun")
  end

  def entity_depends_on_municipality?
    !city_council? && municipality
  end

  def entity_depends_on_other_region?
    !city_council? && !entity_depends_on_municipality?
  end

  def update_operation_attributes
    {
      update: {
        _index: ES_INDEX,
        _type: elasticsearch_type,
        _id: elasticsearch_id,
        data: {
          doc: attributes_for_updating
        }
      }
    }
  end

  def create_operation_attributes
    {
      index: {
        _index: ES_INDEX,
        _type: elasticsearch_type,
        _id: elasticsearch_id,
        data: attributes_for_creating
      }
    }
  end

  def attributes_for_creating
    attributes = {
      year: year,
      amount: executed_amount,
      code: code,
      parent_code: parent_code,
      level: level,
      kind: kind,
      organization_id: organization_id
    }

    attributes.merge!(
      ine_code: municipality.id.to_i,
      province_id: municipality.province_id.to_i,
      autonomy_id: municipality.province.autonomous_region_id.to_i,
    ) if city_council?

    attributes.merge!(
      amount_per_inhabitant: executed_amount_per_inhabitant,
      population: population
    ) unless entity_depends_on_other_region?

    attributes
  end

  def attributes_for_updating
    if entity_depends_on_other_region?
      { amount: executed_amount }
    else
      { amount: executed_amount, amount_per_inhabitant: executed_amount_per_inhabitant }
    end
  end

  def exists?
    @stored_doc = ES_CLIENT.get(index: ES_INDEX, type: elasticsearch_type, id: elasticsearch_id)["_source"]
    true
  rescue Elasticsearch::Transport::Transport::Errors::NotFound
    @stored_doc = nil
    false
  end

  def outdated?
    !@stored_doc || (@stored_doc["amount"].to_f != executed_amount) ||
    (@stored_doc["amount_per_inhabitant"].to_f != executed_amount_per_inhabitant)
  end

  private

  def parsed_attributes
    {
      name: response_item.nom_complert,
      description: response_item.descripcio,
      kind: RecordParser.parse_kind(response_item),
      area: RecordParser.parse_area(response_item),
      code: RecordParser.parse_code(response_item),
      year: RecordParser.parse_year(response_item),
      external_entity_code: RecordParser.parse_external_entity_code(response_item),
      executed_amount: RecordParser.parse_executed_amount(response_item)
    }
  end

  def elasticsearch_id
    "#{organization_id}/#{year}/#{code}/#{kind}"
  end

  def elasticsearch_type
    if area == GobiertoData::GobiertoBudgets::ECONOMIC_AREA_NAME
      GobiertoData::GobiertoBudgets::ECONOMIC_BUDGET_TYPE
    else
      GobiertoData::GobiertoBudgets::FUNCTIONAL_BUDGET_TYPE
    end
  end

  def set_organization_id
    @municipality = INE::Places::Place.find(external_entity_code.to_s[0..-6])

    if city_council?
      @organization_id = municipality.id.to_s
    elsif municipality # dependent entity linked to city council
      @organization_id = "#{municipality.id}-gencat-#{external_entity_code}"
    else  # entity linked to generic region
      autonomous_region = INE::Places::AutonomousRegion.find_by_slug("catalunya")
      @organization_id = "#{autonomous_region.id}-gencat-#{external_entity_code}"
    end
  end

  def set_population
    fallback_years = [year, year-1, year+1, year-2, year+2]
    loop do
      @population = get_population(fallback_years.first)
      fallback_years.shift
      break if population || fallback_years.empty?
    end
  end

  def set_executed_amount_per_inhabitant
    @executed_amount_per_inhabitant = (executed_amount.to_f / population).round(2)
  end

  def get_population(year)
    response = ES_CLIENT.get(
      index: "data",
      type: "population",
      id: "#{municipality.id}/#{year}"
    )
    response["_source"]["value"]
  rescue
    nil
  end

end

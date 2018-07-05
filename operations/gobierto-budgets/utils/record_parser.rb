class RecordParser

  def self.parse_kind(response_item)
    if response_item.tipus_partida == "I"
      GobiertoData::GobiertoBudgets::INCOME
    else
      GobiertoData::GobiertoBudgets::EXPENSE
    end
  end

  def self.parse_area(response_item)
    if response_item.tipus_classif == "E"
      GobiertoData::GobiertoBudgets::ECONOMIC_AREA_NAME
    else
      GobiertoData::GobiertoBudgets::FUNCTIONAL_AREA_NAME
    end
  end

  def self.parse_year(response_item)
    Date.parse(response_item.any_exercici).year
  end

  def self.parse_external_entity_code(response_item)
    response_item.codi_ens.to_i
  end

  def self.parse_code(response_item)
    base_code = response_item.codi_pantalla

    if response_item.descripcio == "Deute públic" && base_code.to_i != 0
      "0#{base_code}" # For 0-Public Debt, children budget lines have the leading zero missing
    elsif base_code.length <= 3
      base_code
    elsif base_code.include?(".") # 123.45 => 123-45
      code_preffix = base_code.split(".").first
      code_suffix  = base_code.split(".").last
      "#{code_preffix}-#{code_suffix}"
    elsif base_code.length >= 4   # 1234 => 123-04 && 12345 => 123-45
      code_preffix = base_code[0..2]
      code_suffix  = format("%02d", base_code[3..-1].to_i)
      "#{code_preffix}-#{code_suffix}"
    end
  end

  def self.parse_executed_amount(response_item)
    response_item.import_dret_oblig.to_f
  end

  def self.calculate_level(parsed_code)
    parsed_code.include?("-") ? 4 : parsed_code.length
  end

  def self.calculate_parent_code(parsed_code, parsed_level)
    if parsed_level == 1
      nil
    elsif parsed_code.include?("-")
      parsed_code.split("-").first
    else
      parsed_code[0..-2]
    end
  end

end

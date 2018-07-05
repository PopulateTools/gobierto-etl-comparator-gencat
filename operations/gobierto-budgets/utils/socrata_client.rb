require_relative "response_item"
require_relative "response_item_processor"
require_relative "execution_record"
require_relative "configuration"

class SocrataClient

  PAGE_SIZE = 2000
  FORECAST_DATASET = "bhg2-qtnp"
  EXECUTION_DATASET = "qtcs-wv8y"

  def initialize
    @client = SODA::Client.new(
      domain: Rails.application.secrets.socrata_host,
      app_token: Rails.application.secrets.socrata_app_token
    )
  end

  def create_budget_lines!(year, exec_summary, debug=false)
    page = 0
    response_items = request_items_page(page, year)

    while response_items.any?
      puts "[INFO] Processing items of page #{page} of year #{year}"
      response_items.each_with_index do |item, index|
        puts "[INFO] Processing item (\##{index}/#{response_items.size})"
        ResponseItemProcessor.process!(ResponseItem.new(item), exec_summary, debug)
      end

      page += 1
      response_items = request_items_page(page, year)
    end
  end

  def update_budget_lines!(previous_updated_at, exec_summary, debug=false)
    page = 0
    response_items = request_outdated_items_page(page, previous_updated_at)

    while response_items.any?
      response_items.each_with_index do |item, index|
        puts "[INFO] Processing item (\##{index}/#{response_items.size}) of page #{page}"
        ResponseItemProcessor.process!(ResponseItem.new(item), exec_summary, debug)
      end

      page += 1
      response_items = request_outdated_items_page(page, previous_updated_at)
    end
  end

  def update_execution!(previous_updated_at, exec_summary, exercise_year=nil)
    operations_log = File.open("operations.log", "w+")

    operations = []
    page = 0
    response_items = request_budgets_execution_page(page, previous_updated_at, exercise_year)

    while response_items.any?
      puts "[INFO] Processing page #{page} of exercise year #{exercise_year}"

      response_items.each_with_index do |item, index|
        execution_record = ExecutionRecord.new(item)

        exec_summary.organization_scanned!(execution_record.organization_id)

        if execution_record.exists?
          operation = execution_record.outdated? ? execution_record.update_operation_attributes : nil
        else
          operation = execution_record.create_operation_attributes
        end

        if operation
          operations << operation
          operations_log.puts(operation)
        end
      end

      if operations.any?
        puts "[INFO] Performing  #{operations.size} operations of page #{page} of exercise year #{exercise_year}..."
        ES_CLIENT.bulk(body: operations)
      end

      page += 1
      operations = []
      response_items = request_budgets_execution_page(page, previous_updated_at, exercise_year)
    end
  ensure
    operations_log.close
  end

  private

  def request_items_page(page, year)
    puts "[INFO] Requesting page #{page} of year #{year}"

    @client.get(FORECAST_DATASET, base_query(page).merge(
      "any_exercici" => "#{year}-01-01T00:00:00.000",
      "$where" => "import > 0"
    ))
  end

  def request_outdated_items_page(page, updated_at)
    @client.get(FORECAST_DATASET, base_query(page).merge(
      "$where" => "import > 0 AND :updated_at > '#{updated_at.strftime("%F")}'"
    ))
  end

  def request_budgets_execution_page(page, updated_at, exercise_year)
    query_attributes = {
      "$order" => ":id ASC",
      "$where" => "import_dret_oblig > 0 AND :updated_at > '#{updated_at.strftime("%F")}'"
    }

    query_attributes.merge!("any_exercici" => "#{exercise_year}-01-01T00:00:00.000") if exercise_year

    query_hash = base_query(page).merge(query_attributes)

    puts "[INFO] Requesting page #{page} of year #{exercise_year}. Offset is #{query_hash['$offset']}"

    @client.get(EXECUTION_DATASET, query_hash)
  end

  def base_query(page)
    query_hash = {
      "$limit" => PAGE_SIZE,
      #"codi_ens" => 801930008,  # For debugging (Ayto. Barcelona)
      "$offset" => page * PAGE_SIZE
    }
    # set FAST_RUN to "true" to only import level 1 lines. This is useful for faster imports in development env
    query_hash["nivell"] = 1 if (ENV["FAST_RUN"] == "true")
    query_hash
  end

end

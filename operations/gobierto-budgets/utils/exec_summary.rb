require 'json'

class ExecSummary

  attr_accessor(
    :processed,
    :unchanged,
    :created,
    :updated,
    :errored,
    :error_messages,
    :skipped_nil_amount,
    :skipped_no_population,
    :skipped_excluded_place,
    :entities,
    :entities_total,
    :entities_matched_place,
    :entities_unmatched_place,
    :entities_created,
    :scanned_organizations_ids,
    :imported_organizations_ids
  )

  def initialize
    @processed = 0
    @unchanged = 0
    @created = 0
    @updated = 0
    @errored = 0
    @error_messages = []
    @skipped_nil_amount = 0
    @skipped_no_population = 0
    @skipped_excluded_place = 0
    @entities = {}
    @entities_created = 0
    @scanned_organizations_ids = []
    @imported_organizations_ids = []
  end

  def finalize_summary
    self.entities_total = entities.size
    self.entities_matched_place = entities.values.select do |entity|
      entity[:place_matched]
    end.size
    self.entities_unmatched_place = entities.values.select do |entity|
      !entity[:place_matched]
    end.size
    self.imported_organizations_ids = imported_organizations_ids.uniq
    self.scanned_organizations_ids = scanned_organizations_ids.uniq
  end

  def to_s
    to_json
  end

  def print
    puts JSON.pretty_generate(JSON.parse to_json)
  end

  def success?
    errored == 0 && error_messages.empty?
  end

  def update!
    self.updated += 1
  end

  def unchanged!
    self.unchanged += 1
  end

  def created!
    self.created += 1
  end

  def skipped_no_population!
    self.skipped_no_population += 1
  end

  def skipped_nil_amount!
    self.skipped_nil_amount += 1
  end

  def skipped_excluded_place!
    self.skipped_excluded_place += 1
  end

  def error!(message)
    self.errored += 1
    self.error_messages << message
  end

  def processed!
    self.processed += 1
  end

  def entity_created!
    self.entities_created += 1
  end

  def add_entity(entity_attributes)
    self.entities[entity_attributes[:id]] = entity_attributes
  end

  def organization_updated!(organization_id)
    self.imported_organizations_ids << organization_id
  end

  def organization_scanned!(organization_id)
    self.scanned_organizations_ids << organization_id
  end

end

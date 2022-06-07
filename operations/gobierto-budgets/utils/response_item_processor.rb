require_relative "response_item"

class ResponseItemProcessor

  def self.process!(item, exec_summary, debug=false)
    item.validate!

    exec_summary.organization_scanned!(item.organization_id)
    create_associated_entity(item, exec_summary) unless item.city_council?

    begin
      if item.outdated?
        print "^" if debug
        item.update!
        exec_summary.update!
        exec_summary.organization_updated!(item.organization_id)
      else
        print "-" if debug
        exec_summary.unchanged!
      end
    rescue Elasticsearch::Transport::Transport::Errors::NotFound
      print "+" if debug
      item.create!
      exec_summary.created!
      exec_summary.organization_updated!(item.organization_id)
    end

  rescue ResponseItem::MissingPopulation
    print ">" if debug
    exec_summary.skipped_no_population!
  rescue ResponseItem::MissingAmount
    print ">" if debug
    exec_summary.skipped_nil_amount!
  rescue ResponseItem::ExcludedPlace
    print ">" if debug
    exec_summary.skipped_excluded_place!
  rescue StandardError => e
    print "!" if debug
    exec_summary.error!(e.to_s)
  ensure
    update_entity_exec_summary(exec_summary, item) unless item.city_council?
    exec_summary.processed!
  end

  def self.create_associated_entity(item, exec_summary)
    entity_attributes = item.attributes_for_associated_entity

    return if GobiertoBudgets::AssociatedEntity.exists?(entity_id: entity_attributes[:entity_id])

    new_entity = GobiertoBudgets::AssociatedEntity

    if new_entity = GobiertoBudgets::AssociatedEntity.create(entity_attributes)
      exec_summary.entity_created!
      puts "Created entity #{entity_attributes[:entity_id]} - #{entity_attributes[:name]}"
    else
      exec_summary.error!("Creation of entity with attributes #{new_entity.attributes} failed. Errors: #{new_entity.errors.full_messages}")
    end
  end
  private_class_method :create_associated_entity

  def self.update_entity_exec_summary(exec_summary, item)
    entity_id = item.entity

    if exec_summary.entities[entity_id]
      exec_summary.entities[entity_id][:count] += 1
    else
      exec_summary.add_entity(
        id: entity_id,
        name: item.name,
        count: 1,
        place_matched: item.place.present?
      )
    end
  end
  private_class_method :update_entity_exec_summary

end

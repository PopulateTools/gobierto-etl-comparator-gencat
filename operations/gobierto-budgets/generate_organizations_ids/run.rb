# Usage:
#
#  - Creates a file with the ids of all existing organizations
#  - Creates a file with the ids of all existing associated entities
#  - Must be ran as a rails runner from gobierto-budgets-comparator-gen-cat
#
# Arguments:
#
#  - 0: Storage dir
#
# Samples:
#
#  cd $DEV_DIR/gobierto-budgets-comparator-gen-cat; bin/rails runner $DEV_DIR/gobierto-etl-comparator-gencat/operations/generat_organization_ids/run.rb $DEV_DIR/gobierto-budgets-comparator-gen-cat/tmp
#

STORAGE_DIR = ARGV[0]

puts "[START] generate_organizations_ids/run.rb  with STORAGE_DIR: #{STORAGE_DIR}"

organizations_ids = INE::Places::Place.all.map(&:id)
File.write("#{STORAGE_DIR}/organization_ids.txt", organizations_ids.join("\n"))

entities_ids = GobiertoBudgets::AssociatedEntity.pluck(:entity_id)
File.write("#{STORAGE_DIR}/entity_ids.txt", entities_ids.join("\n"))

puts "[END] generate_organizations_ids/run.rb"

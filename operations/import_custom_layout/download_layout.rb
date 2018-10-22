#!/usr/bin/env ruby

require "bundler/setup"
Bundler.require

# Description:
#
#  Downloads the layout template from GenCat servers for the specified locales
#
# Arguments:
#
#  - 0: Local storage path
#  - 1: Layout location, provided by GenCat
#  - 2..n: Different locales of the layout that need to be retrieved
#
# Samples:
#
#   ruby $DEV_DIR/gobierto-etl-comparator-gencat/operations/import_custom_layout/download_layout.rb $DEV_DIR/gobierto-etl-comparator-gencat/tmp http://example.com es ca
#

STORAGE_DIR = ARGV[0]
LAYOUT_LOCATION = ARGV[1]
LOCALES = ARGV[2..ARGV.length - 1]
MIN_PAGE_SIZE = 10_000

if ARGV.length < 3
  raise "Incorrect number of arguments. Execute run.rb <local_storage_path> <layout_location> <locales>"
end

puts "[START] Download layout with STORAGE_DIR=#{STORAGE_DIR}, LAYOUT_LOCATION=#{LAYOUT_LOCATION}, LOCALES=#{LOCALES}"

LOCALES.each do |locale|
  layout_file_uri = URI.parse("#{LAYOUT_LOCATION}&idioma=#{locale}")
  local_file_path = "#{STORAGE_DIR}/downloaded_layout_#{locale}.html"

  puts "Saving #{layout_file_uri} into #{local_file_path} ..."

  response_page = Net::HTTP.get(layout_file_uri)

  if response_page.size < MIN_PAGE_SIZE
    raise Exception, "Downloaded page is too small. Check it does not contain errors"
  end

  File.write(local_file_path, response_page)
end

puts "[END] Download layout"

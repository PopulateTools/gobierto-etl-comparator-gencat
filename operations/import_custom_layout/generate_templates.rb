#!/usr/bin/env ruby

require "bundler/setup"
Bundler.require

require "nokogiri"

# Description:
#
#  Takes as input the HTML template as downloaded from Gencat and transforms it by
#  inserting the custom tags, splitting it in header and footer and for each locale.
#  Must be run as a ruby script.
#
# Arguments:
#
#  - 0: Local storage path
#
# Samples:
#
#   ruby $DEV_DIR/gobierto-etl-comparator-gencat/operations/import_custom_layout/generate_templates.rb $DEV_DIR/gobierto-etl-gencat/tmp
#

if ARGV.length != 1
  raise "Incorrect number of arguments. Execute run.rb <local_storage_path>"
end

LOCAL_STORAGE_PATH = ARGV[0]

puts "[START] Generate templates with LOCAL_STORAGE_PATH=#{LOCAL_STORAGE_PATH}"

layout_files_names = Dir.entries(LOCAL_STORAGE_PATH).select do |entry|
  entry =~ /^downloaded_layout_[a-z]{2}\.html$/
end

locales = layout_files_names.map do |file_name|
  file_name.gsub("downloaded_layout_", "").gsub(".html", "")
end

layout_pages = layout_files_names.map do |file_name|
  Nokogiri::HTML(open("#{LOCAL_STORAGE_PATH}/#{file_name}"))
end

layout_pages.each do |layout_page|
  footer_tag = layout_page.xpath("//div[contains(@class, 'fons_footer')]").first
  header_tag = layout_page.xpath("//div[contains(@class, 'contenidor')]").first

  locales.each do |locale|
    File.write("#{LOCAL_STORAGE_PATH}/_footer_#{locale}.html.erb", footer_tag)
    File.write("#{LOCAL_STORAGE_PATH}/_header_#{locale}.html.erb", header_tag)
  end
end

puts "[END] Generate templates"

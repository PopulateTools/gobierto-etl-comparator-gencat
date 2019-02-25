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
JQUERY_LIB_REGEXP = /<script src=.*jquery.*><\/script>/

puts "[START] Generate templates with LOCAL_STORAGE_PATH=#{LOCAL_STORAGE_PATH}"

layout_files_names = Dir.entries(LOCAL_STORAGE_PATH).select do |entry|
  entry =~ /^downloaded_layout_[a-z]{2}\.html$/
end

layout_files_names.map do |file_name|
  locale = file_name.split("_").last.gsub(".html", "")

  puts "Parsing file #{file_name}. Locale is #{locale}"

  layout_page = Nokogiri::HTML(open("#{LOCAL_STORAGE_PATH}/#{file_name}"))

  footer_tag = layout_page.xpath("//div[contains(@class, 'fons_footer')]").first
  header_tag = layout_page.xpath("//div[contains(@class, 'contenidor')]").first
  head_tag = layout_page.xpath("//head").first
  head_content = head_tag.to_s.gsub(/<head>|<\/head>/, "")

  # Update change locale
  header_tag.css("ul.idioma a").each do |link|
    link['href'] = if link['href'].include?("CA")
                     "/locale/ca"
                   elsif link['href'].include?("ES")
                     "/locale/es"
                   elsif link['href'].include?("EN")
                     "/locale/ca"
                   elsif link['href'].include?("OC")
                     "/locale/ca"
                   end
  end

  # comment incompatible version of jQuery
  jquery_lib_line = head_content[JQUERY_LIB_REGEXP]
  head_content.gsub!(jquery_lib_line, "<!-- #{jquery_lib_line} -->")

  files = [
    { name_fragment: "_footer_", content: footer_tag },
    { name_fragment: "_header_", content: header_tag },
    { name_fragment: "_custom_head_content_", content: head_content }
  ]

  files.each do |file|
    file_path = "#{LOCAL_STORAGE_PATH}/#{file[:name_fragment]}#{locale}.html.erb"
    print "Writting #{file_path} ... "
    bytes_written = File.write(file_path, file[:content])
    puts "Wrote #{bytes_written} bytes"
  end
end

puts "[END] Generate templates"

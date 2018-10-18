#!/usr/bin/env ruby

require "bundler/setup"
Bundler.require

STORAGE_DIR = ARGV[0]
LAYOUT_LOCATION = ARGV[1]
LOCALES = ARGV[2..ARGV.length - 1]
MIN_PAGE_SIZE = 10_000

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

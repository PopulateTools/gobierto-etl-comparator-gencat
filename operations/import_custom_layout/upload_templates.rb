#!/usr/bin/env ruby

require "bundler/setup"
Bundler.require

# Description:
#
#  Uploads templates to AWS, for the specified environment bucket and folder
#
# Arguments:
#
#  - 0: Rails (and bucket) environment
#  - 1: Directory were the files are located
#
# Samples:
#
#   ruby $DEV_DIR/gobierto-etl-comparator-gencat/operations/import_custom_layout/upload_templates.rb development $DEV_DIR/gobierto-etl-gencat/tmp
#

if ARGV.length != 2
  raise "Incorrect number of arguments. Execute run.rb <rails_env> <directory>"
end

rails_env = ActiveSupport::StringInquirer.new(ARGV[0])
bucket_env = rails_env.development? || rails_env.dev? ? :dev : rails_env
directory = ARGV[1]

puts "[START] Upload templates to S3 bucket with rails_env=#{rails_env}, directory=#{directory}"

S3_PREFFIX = "GOBIERTO_BUDGETS_COMPARATOR_GENCAT_"
BUCKET_NAME = "gobierto-budgets-comparator-#{bucket_env}"
UPLOADABLE_FILES = Dir.entries(directory).select do |entry|
  entry =~ /^_(header|footer|custom_head_content)_[a-z]{2}\.html\.erb$/
end

s3_client = Aws::S3::Client.new(
  region: ENV.fetch("#{S3_PREFFIX}AWS_REGION"),
  access_key_id: ENV.fetch("#{S3_PREFFIX}AWS_ACCESS_KEY_ID"),
  secret_access_key: ENV.fetch("#{S3_PREFFIX}AWS_SECRET_ACCESS_KEY")
)

UPLOADABLE_FILES.each do |file_name|
  file_path = "#{directory}/#{file_name}"
  object_key = "gencat/custom_views/#{file_name}"

  puts "Uploading #{file_path} to #{BUCKET_NAME}/#{object_key} ..."

  object = Aws::S3::Resource.new(client: s3_client).bucket(BUCKET_NAME).object(object_key)
  object.upload_file(file_path)
  s3_client.put_object_acl(acl: "public-read", bucket: BUCKET_NAME, key: object_key)
end

puts "[END] Upload templates to S3 bucket"

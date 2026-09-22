require 'json'
LATEST_PA_VERSION = 'v1.2.3'
require_relative "lib/partitioned_array/#{LATEST_PA_VERSION}/requires"
DB_SIZE = 10
PARTITION_AMOUNT = 4
OFFSET = 1
PARTITION_ADDITION_AMOUNT = 5

FileUtils.rm_rf('./db/sl')
sl_db = ManagedPartitionedArray.new(max_capacity: 'data_arr_size', has_capacity: true, db_size: DB_SIZE,
                                    partition_amount_and_offset: PARTITION_AMOUNT + OFFSET, db_path: './db/sl', db_name: 'sl_slice')
sl_db.allocate
sl_db.save_everything_to_files!

FileUtils.rm_rf('./db_tests/url_shorten')
db_tests = ManagedPartitionedArray.new(max_capacity: 1000, has_capacity: false, db_size: DB_SIZE,
                                       partition_amount_and_offset: PARTITION_AMOUNT + OFFSET, db_path: './db/url_shorten', db_name: 'url_slice')
db_tests.allocate
db_tests.save_everything_to_files!
puts 'Allocation and file creation complete'

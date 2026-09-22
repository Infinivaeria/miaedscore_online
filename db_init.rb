require 'json'
LATEST_PA_VERSION = 'v1.2.3'
require_relative 'lib/partitioned_array/lib/line_db'



@@secondlife_ai['secondlife_ai'].pad['blog_database', 'blog_profile_table']
@@secondlife_ai[user].pad['blog_database', 'blog_profile_table']
sl_db = ManagedPartitionedArray.new(partition_addition_amount: PARTITION_ADDITION_AMOUNT_SL,
                                    max_capacity: 'data_arr_size', has_capacity: true, db_size: DB_SIZE, partition_amount_and_offset: PARTITION_AMOUNT + OFFSET, db_path: './db/sl', db_name: 'sl_slice')
sl_db.allocate
sl_db.save_everything_to_files!

## URL SHORTENING

 puts "Allocation and file creation complete"

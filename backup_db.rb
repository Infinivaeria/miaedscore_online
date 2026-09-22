# Define the folder to be zipped
puts Dir.pwd
folder_path = "/home/stimk3.4.dev/db"

# Define the location where the zip file will be placed
zip_location = "/home/stimky/db_backup"

# Create the zip file name
zip_file_name = "#{Time.now.strftime('%Y-%m-%d_%H-%M-%S')}_#{File.basename(folder_path)}.zip"

# Create the system call to zip the folder
system("zip -r #{zip_location}/#{zip_file_name} #{folder_path}")
#

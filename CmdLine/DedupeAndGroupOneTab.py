import plyvel
import os

username = os.environ['USERNAME']
# get the machine name from windows environment variables
machine_name = os.environ['COMPUTERNAME']
# C:\Users\alex.fielder\AppData\Local\Microsoft\Edge\User Data\Profile 4\Local Storage\leveldb
# leveldb_data_path = 'C:/Users/' + username + '/AppData/Local/Microsoft/Edge/User Data/Profile 4/Local Storage/leveldb

# Specify the path to your LevelDB directory
db_path = r"C:\Users\alex.fielder\AppData\Local\Microsoft\Edge\User Data\Profile 4\Local Extension Settings\hoimpamkkoehapgenciaoajfkfkpgfop"

# Check if the path is a valid directory
if not os.path.isdir(db_path):
    print(f"The specified path '{db_path}' is not a valid directory.")
else:
    try:
        # Try to open the LevelDB database
        db = plyvel.DB(db_path, create_if_missing=False)  # We do not want to create a new DB if it's missing

        # Iterate over all key, value pairs in the database
        for key, value in db:
            print(key, value)

        db.close()
    except Exception as e:
        print(f"An error occurred while accessing the database: {e}")
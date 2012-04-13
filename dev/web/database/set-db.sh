DB="mydb"
PASS="mysql"

# Create database
mysql --password=$PASS $DB < create-db.sql

# Create and populate table
mysql --password=$PASS $DB < create-table.sql
mysql --password=$PASS $DB < insert-table.sql

# Create user and give permissions
mysql --password=$PASS $DB < create-user.sql
mysql --password=$PASS $DB < grant-user-table.sql

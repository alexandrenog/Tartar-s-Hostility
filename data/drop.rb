require 'sqlite3'
database = SQLite3::Database.new( "tartar.database" )

database.execute "drop table if exists score"
require 'sqlite3'
def dov(v)
	v.each do |x|
		p x
	end
end
database = SQLite3::Database.new( "tartar.database" )
#v=database.execute "delete from score where points < (select avg(points) from score)"
v=database.execute "select * from score order by points"
dov(v)

gets

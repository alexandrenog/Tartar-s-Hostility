class Position
	@@count = 1
	attr_accessor :x, :y
	def initialize(x, y, bool = false)
		@x,@y=x,y
		if(bool)
			puts to_s
		end
		@@count+=1
	end
	def to_s
		"x: #@x, y: #@y"
	end
	def self.add(a,b)
		return Position.new(a.x+b.x,a.y+b.y)
	end
	def self.sub(a,b)
		return Position.new(a.x-b.x,a.y-b.y)
	end
	def self.mult(a,m)
		return Position.new(a.x*m,a.y*m)
	end
	def self.distance(a,b)
		res = Position.sub(a,b)
		return modulo(res)
	end
	def self.modulo(pos)
		return Math.sqrt(pos.x**2+pos.y**2)
	end
	def self.prodInterno(a,b)
		return (a.x*b.x+a.y*b.y)
	end
	def self.intermediario(a,b,t)
		return Position.add(Position.mult(a,(1.0-t)),Position.mult(b,t))
	end
	def self.to_Rad(angle)
		return angle.to_f/180.0 * Math::PI
	end
	def self.to_degree(angle)
		return angle.to_f*180.0 / Math::PI
	end
	def self.le(texto)
		print texto 
		return gets()
	end
	def self.leArrayInt(texto)
		return le(texto).split.map(&:to_i)
	end
	private_class_method :leArrayInt
	def self.crFromUser
		puts @@count.to_s + "ª " + name
		begin
			posArray=leArrayInt("Digite x e y: ")
			bool=posArray.size != 2
			if bool
				puts "Entrada errada, digite novamente"
			end
		end while bool
		return Position.new(posArray[0],posArray[1], true)
	end
end
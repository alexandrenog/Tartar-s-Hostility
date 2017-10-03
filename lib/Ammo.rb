require 'rubygems'
require 'gosu'
require_relative 'utils/position'
require_relative 'utils/time'

class Ammo
	attr_accessor :pos, :mult
	def initialize(pos,vel,window,player,ammo,fromPlayer,colorvariation=nil, mult=1,dist=4000.0)
		@fromPlayer=fromPlayer
		@player=player
		@ammo = ammo
		@window=window
		@dist=dist
		@mult=mult
		@colorvariation=colorvariation
		@pos=Position.new(pos.x.to_f,pos.y.to_f)
		@posinit=Position.new(pos.x.to_f,pos.y.to_f)
		@vel=Position.new(vel.x.to_f,vel.y.to_f)
		@init=(Time.now).to_ms
		@angle=Position.to_degree(-Math.atan2(@vel.x,@vel.y)+Math::PI/2)
	end
	def update
		@pos=Position.add(@pos,@vel);
		if(@fromPlayer)
			# morte da munição depois de 3 segundos
			if (Time.now).to_ms - @init >3000
				@player.popbullet
			end
			# colisao da munição de player contra "things"
			@window.things.each_with_index do |thing,index|
				if(Position.distance(thing.pos,@pos)<(Ammo.radius+7))
					@player.addExp
					@window.things.delete_at(index)
				end
			end
			# colisao da munição de player contra "things"
			@window.bullets.each_with_index do |bullet,index|
				if(Position.distance(bullet.pos,@pos)<(Ammo.radius))
					@player.atualizaTime
					@player.gainHealth((3.0/@window.difficulty.to_f)/bullet.mult)
					@player.addPoints((bullet.mult*10.0).to_i)
					@window.bullets.delete_at(index)
				end
			end
		end
		if(Position.distance(@pos,@player.pos)<((@fromPlayer)?(Ammo.radius):(Ammo.miniradius))+@player.radius)
			@player.lossHealth(@mult,true)
			if @window.bullets.include?(self)
				@window.bullets.delete_at(@window.bullets.index(self))
			end
		end
		if(Position.distance(@posinit,@pos)>=@dist)
			if(@fromPlayer)
				@player.popbullet(self)
			else
				if @window.bullets.include?(self)
					@window.bullets.delete_at(@window.bullets.index(self))
				end
			end
		end
	end
	def draw
		relative_pos=Position.sub(@window.mid,@player.pos)
		draw_pos=Position.add(relative_pos,@pos)
		@ammo.draw_rot(draw_pos.x+@window.sisHorizontal,draw_pos.y+@window.sisVertical,9,@angle,0.5,0.5,1,1,((@colorvariation == nil) ? (0xff_ffffff) : (0xff_000000+@colorvariation)))
	end
	def self.velConst
		5.0
	end
	def self.radius
		21
	end
	def self.miniradius
		10
	end
end
require 'rubygems'
require 'gosu'
require 'sqlite3'
require_relative 'lib/utils/position'
require_relative 'lib/utils/time'
require_relative 'lib/Ammo'
require_relative 'lib/Tank'
require_relative 'lib/Thing'

class Game < Gosu::Window
	attr_reader :mapx, :mapy, :mid , :things, :bullets, :pm, :paused
	attr_accessor :sisHorizontal, :sisVertical, :engineInstance, :mute, :deathSound, :ended, :difficulty
	def initialize(width,height,bool)
		super(width,height,bool)
		self.caption="Game"
		@tankimg = Gosu::Image.new(self, 'media/image/circle.bmp')
		@ammoimg = Gosu::Image.new(self, 'media/image/ammo.bmp')
		@miniammoimg = Gosu::Image.new(self, 'media/image/miniammo.bmp')
		@texture = Gosu::Image.new(self, 'media/image/texture.png')
		@magicfade = Gosu::Image.new(self, 'media/image/magicfade.bmp')
		@heart = Gosu::Image.new(self, 'media/image/heart.bmp')
		@thingimgs =[]
		@lava = Gosu::Image.new(self, 'media/image/lava.png')
		@lavaRotateAngle=0
		@thingimgs << Gosu::Image.new(self, 'media/image/thing_1.bmp')
		@thingimgs << Gosu::Image.new(self, 'media/image/thing_2.bmp')
		@thingimgs << Gosu::Image.new(self, 'media/image/thing_3.bmp')
		@thingimgs << Gosu::Image.new(self, 'media/image/thing_4.bmp')
		@shotSound = Gosu::Sample.new(self, 'media/audio/slimeball.wav')
		@hitSound = Gosu::Sample.new(self, 'media/audio/impact.wav')
		@engineSound = Gosu::Sample.new(self, 'media/audio/engine.wav')
		@deathSound = Gosu::Sample.new(self, 'media/audio/death.wav')
		@healSound = Gosu::Sample.new(self, 'media/audio/heal.wav')
		@mid=Position.new(width/2,height/2)
		@dimx,@dimy=32,18
		@mapx,@mapy=@dimx*100,@dimy*100
		@max_things=@dimx*@dimy/2;
		@pm=mousepos
		@p=Position.new(0,0)
		@engineInstance=@engineSound.play(0.5,1,true)
		@mute=true
		@database=SQLite3::Database.new('data/tartar.database')
		@database.execute "create table if not exists score (id integer primary key, points integer not null);"
		@database.execute "delete from score where points < 10"
		@endscene=false
		@scoreText=""
		@difficulty=1
		@newPlayerPos=true
		init
	end
	def init
		@paused=true
		@ended=false
		@returned=false
		@canreturn=false
		@engineInstance.pause
		@sisHorizontal,@sisVertical=0,0
		@ThingsCreationTime=Time.now.to_ms
		@BulletShootTime=Time.now.to_ms

		playerpos = (@newPlayerPos)?Position.new(@dimx*rand(100),@dimy*rand(100)): @player.pos
		@player = Tank.new(playerpos,self,@tankimg,@ammoimg,@shotSound,@hitSound,@healSound,@heart)
		@things=[]
		@bullets=[]
		(0..@max_things).each do |v|
			@things<<Thing.randThing(@mapx,@mapy,@player,self,@thingimgs)
		end
	end
	def endgame
		@endscene=true
		@scoreText = "Your score is " + @player.points.to_s + " points!"
		@canreturn=true
	end
	def update
		if(@ended)
			endgame
		end
		if(@returned)
			@database.execute "insert into score(points) values (#{@player.points})"
			@endscene=false
			init
		end
		if(!@endscene and !@paused)
			@player.update()
			@bullets.each{ |b| b.update}
			if @things.length<@max_things and Time.now.to_ms-@ThingsCreationTime>1
				@ThingsCreationTime=Time.now.to_ms
				@things<<Thing.randThing(@mapx,@mapy,@player,self,@thingimgs)
			end
			if Time.now.to_ms-@BulletShootTime>280 - (@player.level*1.27)**1.35
				@BulletShootTime=Time.now.to_ms
				indexes=[]
				mindistance=@mapx*@mapy
				index=-1
				for i in 0...(0.12*@max_things)
					indexes<<rand(things.length)
					if(Position.distance(things[indexes[i]].pos,@player.pos)<mindistance&&things[indexes[i]].active)
						mindistance=Position.distance(things[indexes[i]].pos,@player.pos)
						index=indexes[i]
					end
				end
				posSource=things[index].pos
				things[index].auto_delete(@magicfade)
				dif = Position.sub(Position.add(@player.pos,Position.mult(@player.vel,(Position.distance(@player.pos,posSource)/450.0)*60.0/2)),posSource)
				vec = Position.mult(dif,((things[index].value)**0.2-0.2)*Ammo.velConst.to_f*(0.9+0.17*@player.level**0.4)/Position.modulo(dif))
				@bullets<<Ammo.new(posSource,vec,self,@player,@miniammoimg,false,things[index].colorvariation,(19-things[index].value)/8.0)
			end
		end
	end
	def button_down(id)
		if !@endscene then @player.button_down(id) end
		if (id == Gosu::KbQ or id== Gosu::KbEscape) and !@endscene
			@database.execute "insert into score(points) values (#{@player.points})"
			exit
		end
		if (id == Gosu::KbF or id == Gosu::KbP) and !@endscene
			if !@paused then @player.health*=0.5 end
			@player.stuckSpellTime
			@paused=!@paused
		end
		if (id == Gosu::KbSpace or id == Gosu::KbReturn) and @canreturn
			@returned=true
		end
		if (id == Gosu::Kb1 and @paused) 
			@difficulty=1
			@newPlayerPos=false
			init
			@newPlayerPos=true
		end
		if (id == Gosu::Kb2 and @paused) 
			@difficulty=2
			@newPlayerPos=false
			init
			@newPlayerPos=true
		end
		if (id == Gosu::Kb3 and @paused) 
			@difficulty=3
			@newPlayerPos=false
			init
			@newPlayerPos=true
		end
	end
	def button_up(id)
		@player.button_up(id)
	end
	def mousepos
		return Position.new(mouse_x.to_f,mouse_y.to_f)
	end
	def nearBorder
		return ((@mapx-@player.pos.x<=width) or (@player.pos.x<=width) or (@mapy-@player.pos.y<=height) or (@player.pos.y<=height))
	end
	def draw
			#draw_rect(0-@player.pos.x+@sisHorizontal,0-@player.pos.y+@sisVertical,@mapx-@player.pos.x+width+@sisHorizontal,@mapy-@player.pos.y+height+@sisVertical,0xffd00a0a)
		@lavaRotateAngle+=0.08*(rand(5)-2)*@player.level**0.45
		if nearBorder
			@lava.draw_rot(
				width/2+@sisHorizontal,
				height/2+@sisVertical,
				0,@lavaRotateAngle,0.5,0.5,
				(width+100)/@texture.width.to_f,
				(height)/@texture.height.to_f,
				0xff_eeaadd)
		end
			#draw_rect(width/2-50-@player.pos.x+@sisHorizontal,height/2-50-@player.pos.y+@sisVertical,width/2+50+@mapx-@player.pos.x+@sisHorizontal,height/2+50+@mapy-@player.pos.y+@sisVertical,0xef1f1f1f)
		@texture.draw_rot(width/2+@mapx/2+@sisHorizontal-@player.pos.x,height/2+@mapy/2+@sisVertical-@player.pos.y,0,0,0.5,0.5,(@mapx+100)/@texture.width.to_f,(@mapy+100)/@texture.height.to_f,0xff_9a4020)
		@things.each{ |t| t.draw}
		@bullets.each{ |b| b.draw}
		@player.draw()
		dif=Position.sub(mousepos,@mid)
		p=Position.mult(dif,@player.shootmod/Position.modulo(dif))
		@pm=Position.add(p,@mid)
		d_linePos(Position.add(mousepos,Position.new(@sisHorizontal,@sisVertical)),
			Position.add(@mid,Position.new(@sisHorizontal,@sisVertical)),
			0x5006bb06)
		#d_pointPos(Position.add(@pm,Position.new(@sisHorizontal,@sisVertical)),3,0x24bbbbbb)
		d_pointPos(Position.add(mousepos,Position.new(@sisHorizontal,@sisVertical)),4,0xA006bb06)
		if(@endscene)
			draw_rect(width*0.1,height*0.1,width*0.9,height*0.9,0xef1f1f1f,30)
			scr=Gosu::Image.from_text(self, "#{@scoreText}", 'Verdana', 32)
			scr.draw(mid.x-scr.width/2,mid.y*0.9,31)
			record=(@database.execute "select max(points) from score")[0][0]
			if(record != nil and record>=@player.points)
				rec=Gosu::Image.from_text(self, "Record is: #{record}", 'Verdana', 26)
				rec.draw(mid.x-rec.width/2,mid.y*1.1,31)
			elsif(record != nil and record<@player.points)
				nrec=Gosu::Image.from_text(self, "New Record", 'Verdana', 26).draw(mid.x*0.93,mid.y*1.1,31)
				if nrec!=nil then nrec.draw(mid.x-nrec.width/2,mid.y*1.1,31) end
			end
		end
		if(@paused and !@endscene)
			draw_rect(width*0.4,height*0.45,width*0.6,height*0.55,0xef1f1f1f,30)
			pausedtext=Gosu::Image.from_text(self, "Paused(F)", 'Verdana', 32)
			pausedtext.draw(mid.x-pausedtext.width/2,mid.y*0.95,31)
		end
	end
	def mouse_angle
		dif=Position.sub(mousepos,@mid)
		return Math.atan2(dif.x,dif.y)
	end
	def draw_rect(xo,yo,xf,yf,c=0xffffffff,z=0)
		draw_quad(xo,yo,c,xf,yo,c,xf,yf,c,xo,yf,c,z)
	end
	def d_line(xo,yo,xf,yf,c=0xffffffff)
		draw_line(xo,yo,c,xf,yf,c)
	end
	def d_linePos(a,b,c=0xffffffff)
		d_line(a.x,a.y,b.x,b.y,c)
	end
	def d_pointPos(p,raio,c=0xffffffff)
		if( p != nil)
			draw_rect(p.x-raio,p.y-raio,p.x+raio,p.y+raio,c)
			draw_rect(p.x-raio*0.5,p.y-raio*1.5,p.x+raio*0.5,p.y+raio*0.5,c)
			draw_rect(p.x-raio*0.5,p.y-raio*0.5,p.x+raio*0.5,p.y+raio*1.5,c)
			draw_rect(p.x-raio*1.5,p.y-raio*0.5,p.x+raio*0.5,p.y+raio*0.5,c)
			draw_rect(p.x-raio*0.5,p.y-raio*0.5,p.x+raio*1.5,p.y+raio*0.5,c)
		end
	end
end
game = Game.new(1920,1080,true);
game.show()
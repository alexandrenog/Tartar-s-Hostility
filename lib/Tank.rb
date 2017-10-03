require 'rubygems'
require 'gosu'
require_relative 'utils/position'
require_relative 'utils/time'

class Tank
	attr_reader :pos, :level,:exp,:shoots, :radius, :vel, :BulletSpeed, :points
	attr_accessor :health
	def initialize(pos,window,img,ammo,shotSound, hitSound, healSound, heart)
		@pos=Position.new(pos.x.to_f,pos.y.to_f)
		@window=window
		@img = img
		@ammo = ammo
		@shotSound=shotSound
		@shotSoundIntensity=0.3
		@hitSound=hitSound
		@healSound=healSound
		@heart=heart
		@vel,@i,@j=Position.new(0.0,0.0),Position.new(0.1,0.0),Position.new(0.0,0.1)
		@aclx=@acly=0
		@maxvel=2.9
		@shoots=[]
		@BulletSpeed=@MovementSpeed=@Reload=@healthRegen=@level=1
		@aclLevel=0.1*(@level**0.9+2.6)**0.5
		@exp=0
		@radius=30
		atualizaTime
		atualizaSkillTime
		@maxhealth=@health=5+@level
		@HorizontalKtime=@VerticalKtime=0
		@autoshoot=false
		@autoshootImage=Gosu::Image.from_text(@window, "AutoShoot: T, "+((@autoshoot)?("On!"):("Off!")), Gosu.default_font_name, 25)
		@quitimage=Gosu::Image.from_text(@window, "Quit: Q", Gosu.default_font_name, 25)
		@muteStateImage=Gosu::Image.from_text(@window, "Sound: R, "+((!@window.mute)?("On! "):("Off! ")), Gosu.default_font_name, 25)
		@ssimage=Gosu::Image.from_text(@window, "Special Shot: E", Gosu.default_font_name, 25)
		@ss=Gosu::Image.from_text(@window, "SS", Gosu.default_font_name, 25)
		@window.engineInstance.volume=0.0
		@window.engineInstance.resume
		@haveEverKeyDown=false
		@points=0
		@heartbeat=0
		@stuckTime = 0
	end
	def atualizaTime
		@shoottime = Time.now.to_ms
	end	
	def atualizaSkillTime
		@skilltime = Time.now.to_ms
	end
	def chechkdeath
		if(@health<=0.0)
			if !@window.mute then @window.deathSound.play(0.24) end
			@window.ended=true
		end
	end
	def regen
		if(@health<@maxhealth)
			@health+=@healthRegen/(140.0+@level*3)
		end
	end
	def movment
		#integra posição
		@pos=Position.add(@pos,@vel)
		@pos=limitaPos(@pos,0,0,@window.mapx,@window.mapy)
		#integra velocidade
		@vel=Position.add(@vel,Position.new(@aclx,@acly))
		@vel=Position.mult(@vel,0.95)
		#nivela para zero
		if(Position.modulo(@vel)<0.1)
			@vel.x=@vel.y=0.0
		end
		limitaVel
	end
	def update
		chechkdeath
		regen
		movment
		@shoots.each { |x| x.update} #update shoots

		#check collision with "things"
		@window.things.each do |thing|
			if(Position.distance(thing.pos,@pos)<(@radius+15))
				addExp
				lossHealth
				@window.things.delete_at(@window.things.index(thing))
			end
		end
		# auto shoot if enabled and available
		if @autoshoot and canShoot
			atualizaTime
			if(!@window.mute)
				@shotSound.play(@shotSoundIntensity) #play shot sound
			end
			shoot(@window.pm,30,1,shootmod)
		end 
		if(Position.modulo(@vel)>0.01 and !@window.mute)
			@window.engineInstance.volume=1.3*(1.0-Math.exp(-Position.modulo(@vel)/2.0))
		elsif (Position.modulo(@vel)<=0.01 or @window.mute)
			@window.engineInstance.volume=0.0
		end
	end
	def shootmod
		return (370*@BulletSpeed.to_f**0.3)
	end
	def addExp
		addPoints
		@exp+=1
		if(@exp>=exp)
			@level+=1
			@BulletSpeed+=1
			@MovementSpeed+=1
			@Reload+=1
			@maxhealth+=1
			newhealth=@maxhealth*(Math.exp(-@level/10.0))
			@health=((newhealth>@health)?(newhealth):(@health))
			@aclLevel=0.1*(@level**0.8+3.6)**0.5
			@exp=0
		end
	end
	def addPoints(points=10)
		if @level>1 then @points+=points end
	end
	def lossHealth(mult=1,fromBullet=false)
		if fromBullet and !@window.mute
			@hitSound.play(0.6,0.5)
		end
		if @level >1
			@health-=mult*@level**0.43
		end
	end
	def gainHealth(mult=1)
		if !@window.mute then @healSound.play(0.8) end
		@health+=mult*0.7*@level**0.3
		if @health > @maxhealth
			@health=@maxhealth
		end
	end
	def percentage
		return (@exp/exp.to_f)*100.0
	end
	def exp
		expb=0
		for i in 1..@level
			expb+=(i**0.3)*10
		end
		return expb
	end
	def limitaPos(pos,l0,a0,lF,aF)
		x,y=pos.x,pos.y
		if(x<l0)
			x=l0
			@vel.x=0
			lossHealth
		end
		if(x>=lF)
			x=lF-1
			@vel.x=0
			lossHealth
		end
		if(y<a0)
			y=a0
			@vel.y=0
			lossHealth
		end
		if(y>=aF)
			y=aF-1
			@vel.y=0
			lossHealth
		end
		return Position.new(x,y)
	end
	def limitaVel()
		r=(Position.modulo(@vel))/(@maxvel+@MovementSpeed*0.4)
		if(r>1.0)
			@vel = Position.mult(@vel,1.0/r)
		end
	end
	def button_down(id)
		if !@window.paused
			if id == Gosu::KbA
				@aclx=-@aclLevel
				@HorizontalKtime=Time.now.to_ms
			end
			if id == Gosu::KbD
				@aclx=@aclLevel
				@HorizontalKtime=Time.now.to_ms
			end
			if id == Gosu::KbW
				@acly=-@aclLevel
				@VerticalKtime=Time.now.to_ms
			end
			if id == Gosu::KbS
				@acly=@aclLevel
				@VerticalKtime=Time.now.to_ms
			end
			if id == Gosu::MsLeft and canShoot
				atualizaTime
				if(!@window.mute)
					@shotSound.play(@shotSoundIntensity)
				end
				shoot(@window.pm,30,1,shootmod)
			end
			if id == Gosu::KbE and canSpellSkill
				atualizaSkillTime
				if(!@window.mute)
					@shotSound.play(@shotSoundIntensity*4.0)
				end
				 n=18
				 ang=rand((360.0/n).to_i)
				 1.upto(n){ |index| shoot(Position.add(@window.mid,Position.new(100*Math.cos(Position.to_Rad(index*360.0/n+ang)),100*Math.sin(Position.to_Rad(index*360.0/n+ang)))),1,(rand(2)+16)/12.0)}
			end
			@haveEverKeyDown=true
		end
		if id == Gosu::KbT
			@autoshoot=!@autoshoot
			@autoshootImage=Gosu::Image.from_text(@window, "AutoShoot: T, "+((@autoshoot)?("On!"):("Off!")), Gosu.default_font_name, 25)
		end
		if (id == Gosu::KbR or id == Gosu::KbM)
			@window.mute=!@window.mute
			@muteStateImage=Gosu::Image.from_text(@window, "Sound: R, "+((!@window.mute)?("On! "):("Off! ")), Gosu.default_font_name, 25)
		end
	end
	def canShoot
		return 	Time.now.to_ms - @shoottime > 400 - (@Reload**0.4)*45
	end
	def canSpellSkill
		return 	Time.now.to_ms - @skilltime > skillcooldown
	end
	def skillcooldown
		12000/(@level**0.2)
	end
	def shoot(windowpos,randomness=30,alfa=1,d=1000)
		target=Position.add(windowpos,Position.new(rand(randomness)-randomness/2,rand(randomness)-randomness/2))
		dif = Position.sub(target,Position.new(@window.width/2,@window.height/2))
		vec = Position.mult(dif,1.0/Position.modulo(dif))
		xvec = Position.mult(vec,Ammo.velConst+alfa*@BulletSpeed/1.7)
		pos = Position.add(@pos,Position.mult(vec,@radius+Ammo.radius))
		@shoots<<Ammo.new(pos,xvec,@window,self,@ammo,true,nil,(0.15+(@window.difficulty-1)*0.5),d)
	end
	def button_up(id)
		if(@haveEverKeyDown and !@window.paused)
			if id == Gosu::KbA
				@aclx+=@aclLevel
			end
			if id == Gosu::KbD
				@aclx+=-@aclLevel
			end
			if id == Gosu::KbW
				@acly+=@aclLevel
			end
			if id == Gosu::KbS
				@acly+=-@aclLevel
			end
		end
	end
	def stuckSpellTime
		@stuckTime=Time.now.to_ms - @skilltime
	end
	def updatePausedSkillTime
		@skilltime=Time.now.to_ms-@stuckTime
	end
	def draw
		if @window.paused then updatePausedSkillTime end
		#desenho do tank e das muniçoes
		@window.sisHorizontal = @vel.x*5*(1.0-Math.exp(-(Time.now.to_ms-@HorizontalKtime+3000)/1000.0))
		@window.sisVertical = @vel.y*5*(1.0-Math.exp(-(Time.now.to_ms-@VerticalKtime+3000)/1000.0))
		
		@img.draw_rot((@window.width/2+@window.sisHorizontal)+(rand(10).to_f-5)/5,(@window.height/2+@window.sisVertical)+(rand(10).to_f-5)/5,10,Position.to_degree(-@window.mouse_angle+Math::PI)+(rand(10).to_f-5)/4,0.5,0.5,1,1,0xff_f09060)
		@shoots.each { |x| x.draw}

		# Level e exp
		largura=240
		pini=Position.new(@window.mid.x*1.8-largura/2,@window.mid.y*2*0.9)
		pend=Position.add(pini,Position.new(largura,20))
		pendExp=Position.add(pini,Position.new((largura/100)*percentage,20))
		@window.draw_rect(pini.x,pini.y,pend.x,pend.y,0xdf3f1f00)
		@window.draw_rect(pini.x,pini.y,pendExp.x,pendExp.y,0xffdf9f00)
		posLevelText=Position.add(pini,Position.new(largura/2-35-50,-35))
		Gosu::Image.from_text(@window, "LEVEL #{@level} | DIFF #{@window.difficulty}", Gosu.default_font_name, 25).draw(posLevelText.x,posLevelText.y,20)

		# Vida e vida maxima
		pini=Position.new(@window.mid.x-150,@window.mid.y*2*0.9)
		pend=Position.add(pini,Position.new(1.5*2*100,20))
		pendLife=Position.add(pini,Position.new(1.5*2*(100*@health.to_f/@maxhealth),20))
		@window.draw_rect(pini.x,pini.y,pend.x,pend.y,0xf33f0000)
		@window.draw_rect(pini.x,pini.y,pendLife.x,pendLife.y,0xffdf0000)
		pdraw=Position.add(pini,Position.new(-25,10))
		@heartbeat+=Math.exp(-3*@health.to_f/@maxhealth)
		@heart.draw_rot(pdraw.x,pdraw.y,12,14.0*Math.sin(@heartbeat),0.5,0.5,0.45,0.45,0xee_aa77ff)
		ptext=Position.add(pini,Position.new(1.5*100-30,-2))
		n=(100*@health.to_f/@maxhealth).to_i
		n=(n>=0 ? n : 0)
		Gosu::Image.from_text(@window, "#{n}%", Gosu.default_font_name, 22).draw(ptext.x,ptext.y,20)

		#points
		posScoreText=Position.add(pini,Position.new(100,-40))
		Gosu::Image.from_text(@window, "Score: #{@points}", Gosu.default_font_name, 25).draw(posScoreText.x,posScoreText.y,20)

		#barra da skill 
		prct = (Time.now.to_ms - @skilltime)/skillcooldown.to_f
		prct = ((prct>1.0)?(1):(prct))
		pini=Position.new(@window.mid.x*0.08,@window.mid.y*0.2)
		pend=Position.add(pini,Position.new(14,@window.mid.y*2*0.8))
		pendcooldown=Position.add(pini,Position.new(14,@window.mid.y*2*0.8*(1.0-prct)))
		@window.draw_rect(pini.x,pini.y,pend.x,pend.y,((prct<1)?(0xff8f008f):(0xffdf00df)))
		@window.draw_rect(pini.x,pini.y,pendcooldown.x,pendcooldown.y,(0xff3f003f))
		@ss.draw(pend.x-22,pend.y+8,25)

		#comandos e autoshoot
		y=10
		@autoshootImage.draw(10,y,25)
		y+=10+@autoshootImage.height
		@muteStateImage.draw(10,y,25)
		y=10
		@quitimage.draw(@window.width-(10+@quitimage.width),y,25)
		y+=10+@quitimage.height
		@ssimage.draw(@window.width-(10+@ssimage.width),y,25)
	end
	def popbullet(bullet=nil)
		if(bullet ==nil)
			@shoots.delete_at(0)
		elsif(bullet !=nil and @shoots.index(bullet))
			@shoots.delete_at(@shoots.index(bullet))
		end
	end
end
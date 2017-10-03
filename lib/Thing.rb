require_relative 'utils/position'
require_relative 'utils/time'
class Thing
	attr_reader :pos, :active, :colorvariation
	def initialize(pos,player,window,imgs)
		@imgs=imgs
		@index=rand(@imgs.length)
		@lastSpriteChange=Time.now.to_ms
		@endinginit=Time.now.to_ms
		@pos=pos
		@player=player
		@window=window
		@active=true
		@v=(2+rand(13))
		@colorvariation=(15-@v)*0x00110000+@v*0x00001100+(15-@v)*0x00000011
	end
	def self.randThing(limitx,limity,player,window,imgs)
		return Thing.new(Position.new(rand(limitx),rand(limity)),player,window,imgs)
	end
	def value
		return @v
	end
	def auto_delete(img)
		@active=false
		@imgs=[img]
		@endinginit=Time.now.to_ms
	end
	def update
		if(!@active and Time.now.to_ms-@endinginit>500)
			@window.things.delete_at(@window.things.index(self))
		end
	end
	def draw
		update
		relative_pos=Position.sub(@window.mid,@player.pos)
		draw_pos=Position.add(relative_pos,@pos)
		if(@active)
			if(Time.now.to_ms - @lastSpriteChange > 700)
				@lastSpriteChange=Time.now.to_ms
				@index=rand(@imgs.length)
			end
			@imgs[@index].draw_rot(draw_pos.x+@window.sisHorizontal,draw_pos.y+@window.sisVertical,5,0,0.5,0.5,0.41,0.41,0xdd_000000+@colorvariation)
		else
			diftime=Time.now.to_ms-@endinginit+130
			@imgs[0].draw_rot(draw_pos.x+@window.sisHorizontal,draw_pos.y+@window.sisVertical,5,diftime,0.5,0.5,1-450.0/diftime,1-550.0/diftime,0xdd_ffffff)
		end
	end
end
-- title:  Mario Lottery
-- author: SSAST
-- desc:   Time to clear your Steam wishlist
-- script: lua

W=240
H=136

n_rounds=4
cur_round=1
coin_per_round=3

sprites={
	run1=0,
	run2=2,
	jump=4,
	mushroom=6,
	ground=32,
	brick=34,
	qmark1=36,
	qmark2=38,
	qmark3=40,
	cloud=64,
	bush=68,
	hill=72,
	coin=128
}

-- 0: round init
-- 1: running
-- 2: lottery
-- Others TODO
cur_scene=0
-- Time of entering current scene
scene_start=0

ROUND_INIT_DUR=2000

function change_scene(id)
	cur_scene=id
	if id==1 then set() end
	scene_start=time()
end

function spr_c(id,x,y,w,h,keyc,scale)
	scale=scale or 1
	spr(sprites[id],x-w*4*scale,y-h*4*scale,keyc or 6,
	    scale,0,0,w,h)
end

function ease_sineabs(x)
	x = math.sin(x * math.pi / 2)
	return math.abs(x)
end

function ease_sinesq(x)
	x = math.sin(x * math.pi / 2)
	x = (2 - x) * x
	return x
end

function print_c(text,x,y,colour,scale)
	scale=scale or 1
	local w=print(text,999,999,colour,true,scale)
	print(text,x-w//2,y-(6*scale)//2,colour,true,scale)
end

function round_init_screen(t)
	cls(0)
	spr_c('mushroom',W*0.382,H*0.5,2,2)
	print_c('x',W/2,H/2,7,2)
	print_c(tostring(n_rounds-cur_round+1),W*0.618,H/2,7,2)

	if t>=ROUND_INIT_DUR then
		change_scene(1)
	end
end

function set()
	requested_jump=nil
	dur_per_pixel=12
	bias=0
	block={}
	for i=1,6 do 
		block[i]={pos=W/2+(i-1)*48,frame=0}
	end
	cloud_pos=224
	grass={}
	mount={}
	on_jump=nil
end

function spr_pix(id, dx, dy)
	id = id + (dx // 8) + (dy // 8) * 16
	dx = dx % 8
	dy = dy % 8
	local byte = peek(0x4000 + id * 32 + dx // 2 + dy * 4)
	if dx % 2 == 0 then
		return byte % 16
	else
		return byte // 16
	end
end

function spr_cfs(id,x,y,w,h,keyc,xscale,yscale,shadowc)
	id = sprites[id]
	w = w * 8
	h = h * 8
	x = math.floor(0.5 + x - w * xscale / 2)
	y = math.floor(0.5 + y - h * yscale / 2)
	local rw, rh, dx, dy, xx, yy, c, last_opaque
	rw = math.max(1, math.floor(0.49 + w * xscale))
	rh = math.max(1, math.floor(0.49 + h * yscale))
	for dy = 0, rh-1 do
		last_opaque = -1
		for dx = 0, rw-1 do
			x0 = math.floor(0.49 + dx / rw * w)
			y0 = math.floor(0.49 + dy / rh * h)
			c = spr_pix(id, x0, y0)
			if c ~= keyc then
				pix(x + dx, y + dy, c)
				last_opaque = 4
			elseif last_opaque > 0 then
				last_opaque = last_opaque - 1
				pix(x + dx, y + dy, shadowc)
			end
		end
		for dx = 0, last_opaque-1 do
			pix(x + rw + dx, y + dy, shadowc)
		end
		if last_opaque == -1 then
			for dx = 0, 3 do
				pix(x + rw//2 + dx, y + dy, shadowc)
			end
		end
	end
end

function coin(t,i)
	local s = t >= 700 and 2 or ease_sinesq(t/700)+1
	local squeeze = ease_sineabs(t/700)
	spr_cfs('coin',W/2+2,H/2-1,4,4,6,s*squeeze,s,0)
	if t<=2000 then
		lottery_outcome=math.random(0,999)
	elseif t<=3000 then
		lottery_outcome=
		  (lottery_outcome-lottery_outcome%100)+
				math.random(0,99)
	elseif t<=4000 then
		lottery_outcome=
		  (lottery_outcome-lottery_outcome%10)+
				math.random(0,9)
	end
end

function paint(t)
    for i=1,#mount do
        spr_c('hill',mount[i].posx,mount[i].posy,8,4)
    end
    for i=1,#grass do
        spr_c('bush',grass[i],H-32,4,2)
    end
    spr_c('cloud',cloud_pos,16,4,4)
    for i=1,16 do
        spr_c('ground',(i-1)*16+8-bias%16,H-16,2,2)
        spr_c('ground',(i-1)*16+8-bias%16,H,2,2)
    end
    for i=1,#block do
        if (i%2==1) then
            spr_c('brick',block[i].pos,H*0.4,2,2)
        elseif block[i].frame<=1 then
            spr_c('qmark1',block[i].pos,H*0.4,2,2)
        elseif block[i].frame==2 or block[i].frame==5 then
            spr_c('qmark2',block[i].pos,H*0.4,2,2)
        else
            spr_c('qmark3',block[i].pos,H*0.4,2,2)
        end
    end
	if on_jump then
		local x=(t-on_jump)/12
		local a=0.015
		x=math.fmod(x,80)
		if t-on_jump >= 960*coin_per_round then x = 51 end
		if x>25 and x<=50 then x=50-x end
		local h=a*x*x-(25*a+34/25)*x+H-32
		if x<50 then
			spr_c('jump',W/2,h,2,2)
		else
			spr_c('run2',W/2,H-32,2,2)
		end
		for i=1,coin_per_round do
			if t-on_jump>960*(i-1)+250 then coin(t-on_jump-250-960*(i-1),i) end
		end
    elseif (t//300)%2==0 then
        spr_c('run1',W/2,H-32,2,2)
    else
        spr_c('run2',W/2,H-32,2,2)
    end
end

last_grass=999
last_mount=999

function running_screen(t)
	-- Button #4 (P1's A button)
	-- Mapped to keyboard Z by default
	if btnp(4) and not requested_jump then requested_jump=1 end

	cls(12)
	if on_jump then
		if false then change_scene(2) end

	elseif t%dur_per_pixel then 
		bias=bias+1
		-- move blocks.grass and mountain
		for i=1,#block do 
			block[i].pos=block[i].pos-1
			if block[i].pos<-8 then block[i].pos=280 end
			if bias%20==0 then block[i].frame=(block[i].frame+1)%6 end
			if requested_jump==1 and i%2==0 and block[i].pos==120 then
				on_jump=t
			end
		end
		if bias%10==0 then
			cloud_pos=cloud_pos-1
			if cloud_pos<-16 then cloud_pos=256 end
		end
		dump={}
		for i=1,#grass do
			grass[i]=grass[i]-1
			if grass[i]<-16 then dump[#dump+1]=i end 
		end
		for i=1,#dump do table.remove(grass,dump[i]) end
		dump={}
		for i=1,#mount do
			if bias%2 == 0 then
				mount[i].posx=mount[i].posx-1
			end
			if mount[i].posx<-32 then dump[#dump+1]=i end
		end
		for i=1,#dump do table.remove(mount,dump[i]) end
		
		-- add grass and mountain
		if bias%100==1 then
			local p=math.random()
			if last_grass>=2 or p<0.4 then
				local num=math.random(1,3)
				for i=1,num do
					grass[#grass+1]=256+(i-1)*16
				end
				last_grass=0
			else
				last_grass=last_grass+1
			end
		elseif bias%200==50 then
			local p=math.random()
			if last_mount>=5 or p<0.5 then
				local num=math.random(8,13)
				mount[#mount+1]={posx=288,posy=H-23-num}
				last_mount=0
			else
				last_mount=last_mount+1
			end
		end
	end
	
	paint(t)
end
lottery_outcome=-1

function lottery_screen(t)
	cls(7)
	coin(t,1)
	if t>=4000 then
		if btnp(4) then
			cur_round=cur_round+1
			if (cur_round>n_rounds) then 
				change_scene(3)
			else
				change_scene(0)
			end
		end
	end
	print_c(string.format('%03d',lottery_outcome),
	        W/2,H/2,0,2)
end

function TIC()
	local t=time()-scene_start
	if cur_scene == 0 then
		round_init_screen(t)
	elseif cur_scene == 1 then
		running_screen(t)
	elseif cur_scene == 2 then
		lottery_screen(t)
	end
end

-- <TILES>
-- 000:666666606666666666666666666666666666666666600000660d77776607dddd
-- 001:0066666606666666066666660666666606666666000006667777d066ddddd066
-- 002:666666606666666666666666666666666666666666600000660d77776607dddd
-- 003:0066666606666666066666660666666606666666000006667777d066ddddd066
-- 004:666666606666666666666666666666666666666666600000660d77776607dddd
-- 005:0066666606666666066666660666666606666666000006667777d066ddddd066
-- 006:6666669966666999666699996669999966999999699888996988888999888889
-- 007:9966666698866666888866668888866698889966999999969999999699998899
-- 016:6607dd0d6607dd0d6607dd0d6007dddd060ddddd660ddddd6660000066660666
-- 017:dd0dd066dd0dd066dd0dd060dddd0006ddddd066ddddd0660000066666606666
-- 018:6607dddd6607dd0d6607dd0d6007dddd600ddddd660ddddd6660000066666066
-- 019:ddddd066dd0dd066dd0dd066dddd0006ddddd006ddddd0660000066666066666
-- 020:6607dddd6607d00d6607ddd06007dddd060ddddd660ddddd6660000066660666
-- 021:ddddd066ddd00066dd0dd066dddd0006ddddd060ddddd0660000066666606666
-- 022:9988888999988899999999996988877766667777666677776666777766666777
-- 023:9999888999999889999999997778889677776666779766667797666679766666
-- 032:4ffffffff4444444f4444444f4444444f4444444f4444444f4444444f4444444
-- 033:f04ffff440f4444040f4444040f4444040f044404040000440fffff040f44440
-- 034:ffffffff44444440444444400000000044404444444044444440444400000000
-- 035:ffffffff44444440444444400000000044404444444044444440444400000000
-- 036:6444444449999999490999994999944449994400499944094999440949999009
-- 037:4444444699999990999990904499999004499990944099909440999044409990
-- 038:6444444444444444440444444444444444444400444444044444440444444004
-- 039:4444444644444440444440404444444004444440444044404440444044404440
-- 040:6444444442222222420222224222244442224400422244024222440242222002
-- 041:4444444622222220222220204422222004422220244022202440222044402220
-- 048:f4444444f444444400444444ff004444f4ff0000f444fff0f444444040000004
-- 049:40f4444040f444400f4444400f444440f4444440f4444440f4444400f0000004
-- 050:4444444044444440444444400000000044404444444044444440444400000000
-- 051:4444444044444440444444400000000044404444444044444440444400000000
-- 052:4999999449999994499999994999999449999994490999994999999900000000
-- 053:4000999040999990009999904999999040999990009990909999999000000000
-- 054:4444444444444444444444444444444444444444440444444444444400000000
-- 055:4000444040444440004444404444444040444440004440404444444000000000
-- 056:4222222442222224422222224222222442222224420222224222222200000000
-- 057:4000222040222220002222204222222040222220002220202222222000000000
-- 064:6666666666666666666666666666666666666666666666666666666666666666
-- 065:66666600666660776660077766077777660777776607777760777cc70777c777
-- 066:00666666770666667770666677706066777707067c77777077c7777077777770
-- 067:6666666666666666666666666666666666666666666666666666666666666666
-- 068:6666666666666666666666666666666666666666666666666666666666666666
-- 069:66666600666660bb66600bbb660bbbbb660bbbbb660bbbbb60bbb33b0bbb3bbb
-- 070:00666666bb066666bbb06666bbb06066bbbb0b06b3bbbbb0bb3bbbb0bbbbbbb0
-- 071:6666666666666666666666666666666666666666666666666666666666666666
-- 072:6666666666666666666666666666666666666666666666666666666666666666
-- 073:6666666666666666666666666666666666666666666666666666666666666666
-- 074:6666666666666666666666666666666066666603666660336666033366603333
-- 075:6666600066000333003333333333333333333333333333333333333333333333
-- 076:0006666633300066333333003333303333330003333300033333000330030003
-- 077:6666666666666666666666660666666630666666330666663330666633330666
-- 078:6666666666666666666666666666666666666666666666666666666666666666
-- 079:6666666666666666666666666666666666666666666666666666666666666666
-- 080:6666600066660777666077776667777760077777077777770777777760777777
-- 081:7777777777777777777777777777777777777777777777777777777777777777
-- 082:7777777777777777777777777777777777777777777777777777777777777777
-- 083:0660666606070666707706667777060677777070777777707777777077777706
-- 084:6666600066660bbb6660bbbb666bbbbb600bbbbb0bbbbbbb0bbbbbbb60bbbbbb
-- 085:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 086:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 087:06606666060b0666b0bb0666bbbb0606bbbbb0b0bbbbbbb0bbbbbbb0bbbbbb06
-- 088:6666666666666666666666666666666666666666666666666666666666666666
-- 089:6666666666666666666666666666666066666603666660336666033366603333
-- 090:6603333360333333033333333333333333333333333333333333333333333333
-- 091:3333333333333333333333333333333333333333333333333333333333333333
-- 092:3003303330033333300333333333333333333333333333333333333333333333
-- 093:3333306633333306333333303333333333333333333333333333333333333333
-- 094:6666666666666666666666660666666630666666330666663330666633330666
-- 095:6666666666666666666666666666666666666666666666666666666666666666
-- 096:66077c77666077c76666077c6666077766666000666666666666666666666666
-- 097:777777777c777777ccc777cc77cccccc7777cc77077777706007770666600066
-- 098:7c777777c7777777cc7777c77ccccc7777ccc777777777770077770066000066
-- 099:7777706677777706777777707777777677777006077006666006666666666666
-- 100:660bb3bb6660bb3b66660bb366660bbb66666000666666666666666666666666
-- 101:bbbbbbbbb3bbbbbb333bbb33bb333333bbbb33bb0bbbbbb0600bbb0666600066
-- 102:b3bbbbbb3bbbbbbb33bbbb3bb33333bbbb333bbbbbbbbbbb00bbbb0066000066
-- 103:bbbbb066bbbbbb06bbbbbbb0bbbbbbb6bbbbb0060bb006666006666666666666
-- 104:6666666666666666666666666666666066666603666660336666033366603333
-- 105:6603333360333333033333333333333333333333333333333333333333333333
-- 106:3333333333333333333333333333333333333333333333333333333333333333
-- 107:3333333333333333333333333333333333333333333333333333333333333333
-- 108:3333333333333333333333333333333333333333333333333333333333333333
-- 109:3333333333333333333333333333333333333333333333333333333333333333
-- 110:3333306633333306333333303333333333333333333333333333333333333333
-- 111:6666666666666666666666660666666630666666330666663330666633330666
-- 112:6666666666666666666666666666666666666666666666666666666666666666
-- 113:6666666666666666666666666666666666666666666666666666666666666666
-- 114:6666666666666666666666666666666666666666666666666666666666666666
-- 115:6666666666666666666666666666666666666666666666666666666666666666
-- 116:6666666666666666666666666666666666666666666666666666666666666666
-- 117:6666666666666666666666666666666666666666666666666666666666666666
-- 118:6666666666666666666666666666666666666666666666666666666666666666
-- 119:6666666666666666666666666666666666666666666666666666666666666666
-- 120:6603333360333333033333336666666666666666666666666666666666666666
-- 121:3333333333333333333333336666666666666666666666666666666666666666
-- 122:3333333333333333333333336666666666666666666666666666666666666666
-- 123:3333333333333333333333336666666666666666666666666666666666666666
-- 124:3333333333333333333333336666666666666666666666666666666666666666
-- 125:3333333333333333333333336666666666666666666666666666666666666666
-- 126:3333333333333333333333336666666666666666666666666666666666666666
-- 127:3333306633333306333333306666666666666666666666666666666666666666
-- 128:6666666666666666666666696666669966666999666699996669999966999994
-- 129:6666999969999999999999999999944499944999944999994999999999999999
-- 130:9999666699999996999999994449999999944999999994499999999499999999
-- 131:6666666666666666966666669966666699966666999966669999966649999966
-- 132:6666666666666666666666666666666666666666666666666666666666666666
-- 133:6666666666666666666666666666666666666666666666666666666666666666
-- 134:6666666666666666666666666666666666666666666666666666666666666666
-- 135:6666666666666666666666666666666666666666666666666666666666666666
-- 136:6666666666666666666666696666669966666999666699996669999966999999
-- 137:6666999969999999999999999999999999999444999449999449999949999999
-- 138:9999666699999996999999999999999944499999999449999999944999999994
-- 139:6666666666666666966666669966666699966666999966669999966699999966
-- 144:6699994969999499699994996999499999994994999499499994994999949949
-- 145:9999999999999999999999999999999999999999999999999999999999999999
-- 146:9999999999999999999999999999999999999999999999999999999999999999
-- 147:9499996699499996994999969992999649929999949929999499299994992999
-- 148:6666666666666666666666666666666666666666666666666666666666666666
-- 149:6666666666666666666666666666666666666666666666666666666666666666
-- 150:6666666666666666666666666666666666666666666666666666666666666666
-- 151:6666666666666666666666666666666666666666666666666666666666666666
-- 152:6699999469999949699999496999949999999499999949949999499499994994
-- 153:9999999999999999999999999999999949999999999999999999999999999999
-- 154:9999999999999999999999999999999999999994999999999999999999999999
-- 155:4999996692999996929999969929999699299999499299994992999949929999
-- 160:9994994999949949999499499999499469994999699994996999949966999949
-- 161:9999999999999999999999999999999999999999999999999999999999999999
-- 162:9999999999999999999999999999999999999999999999999999999999999999
-- 163:9499299994992999949929994990499999909996990499969909999690499966
-- 164:6666666666666666666666666666666666666666666666666666666666666666
-- 165:6666666666666666666666666666666666666666666666666666666666666666
-- 166:6666666666666666666666666666666666666666666666666666666666666666
-- 167:6666666666666666666666666666666666666666666666666666666666666666
-- 168:9999499499994994999949949999949969999499699999496999994966999994
-- 169:9999999999999999999999994999999999999999999999999999999999999999
-- 170:9999999999999999999999999999999499999999999999999999999999999999
-- 171:4992999949929999499299999924999999299996904999969099999604999966
-- 176:6699999466699999666699996666699966666699666666696666666666666666
-- 177:9999999949999999944999999990099999999000999999996999999966669999
-- 178:9999999999999990999990049990049900049999999999999999999699996666
-- 179:0499996649999666999966669996666699666666966666666666666666666666
-- 180:6666666666666666666666666666666666666666666666666666666666666666
-- 181:6666666666666666666666666666666666666666666666666666666666666666
-- 182:6666666666666666666666666666666666666666666666666666666666666666
-- 183:6666666666666666666666666666666666666666666666666666666666666666
-- 184:6699999966699999666699996666699966666699666666696666666666666666
-- 185:4999999992299999999009999999900099999999999999996999999966669999
-- 186:9999999099999004999004990004999999999999999999999999999699996666
-- 187:4999996699999666999966669996666699666666966666666666666666666666
-- </TILES>

-- <WAVES>
-- 000:00000000ffffffff00000000ffffffff
-- 001:0123456789abcdeffedcba9876543210
-- 002:0123456789abcdef0123456789abcdef
-- </WAVES>

-- <SFX>
-- 000:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000304000000000
-- </SFX>

-- <PALETTE>
-- 000:0000001d2b537e2553008751ab52365f574fc2c3c7fff1e8ff004dffa300ffec2700e43629adff83769cff77a8ffccaa
-- </PALETTE>


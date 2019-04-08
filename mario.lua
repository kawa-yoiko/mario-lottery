-- title:  Mario Lottery
-- author: SSAST
-- desc:   Time to clear your Steam wishlist
-- script: lua

W=240
H=136

n_rounds=4
cur_round=0

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
	scene_start=time()
end

function spr_c(id,x,y,w,h,keyc)
	spr(id,x-w*4,y-h*4,keyc or -1,
	    1,0,0,w,h)
end

function print_c(text,x,y,colour,scale)
	scale=scale or 1
	local w=print(text,999,999,colour,false,scale,true)
	print(text,x-w//2,y-(6*scale)//2,colour,false,scale,true)
end

function round_init_screen(t)
	cls(0)
	spr_c(0,W*0.382,H*0.5,2,2)
	print_c('x',W/2,H/2,12,2)
	print_c(tostring(n_rounds-cur_round),W*0.618,H/2,12,2)

	if t>=ROUND_INIT_DUR then
		change_scene(1)
	end
end

function running_screen(t)
	cls(8)
end

function TIC()
	local t=time()-scene_start
	if cur_scene == 0 then
		round_init_screen(t)
	elseif cur_scene == 1 then
		running_screen(t)
	end
end

-- <TILES>
-- 000:0ffffffffdccccccfdddddddfdddddddfdddfdddfdddfdddfdddfdddfdddfddd
-- 001:fffffff0ccccccdfdddddddfdddddddfdfdddddfdfdddddfdfdddddfdfdddddf
-- 016:fdddddddfdddddddfdddddddfeeeeeeefeeeeeeefeeeeeeefeeeeeee0fffffff
-- 017:dddddddfdddddddfdddddddfeeeeeeefeeeeeeefeeeeeeefeeeeeeeffffffff0
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
-- 000:1a1c2c5d275db13e53ef7d57ffcd75a7f07038b76425717929366f3b5dc941a6f673eff7f4f4f494b0c2566c86333c57
-- </PALETTE>


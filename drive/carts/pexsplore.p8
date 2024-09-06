pico-8 cartridge // http://www.pico-8.com
version 42
__lua__

#include serial.p8
#include menu.p8
#include utils.p8
#include tween.lua

bg_color=129
bar_color_1=12
bar_color_2=-4

cart_dir='carts'
label_dir='labels'
carts={}
labels={}

-- menu for each cartridge
cart_options=menu_new({
  {label='play',func=function()
    make_transition_tween(carts:cur())
  end},
  {label='favourite',func=function()sfx(1)end},
  {label='download',func=function()sfx(1)end},
  {label='save music',func=function()sfx(1)end},
  {label='similar carts',func=function()sfx(1)end},
  {label='back',func=function()
    sfx(3)
    cart_tween_up()
    cart_tween_state = 1
  end},
})

-- load label into slot into memory
function load_label(cart, slot)
  -- load cartridge art of current cartridge into memory
  label_name=tostring(cart.filename) .. '.64.p8'
  if tcontains(labels, label_name) then
    reload(slot*0x1000, 0x0000, 0x1000, label_dir .. '/' .. label_name)
  end
end

-- can pass -1 to slot to skip label
function draw_label(x, y, w, slot)
  rectfill(x-w/2, y-w/2, x+w/2, y+w/2, 0)
  -- render a 64x64 label from memory in 'scanlines'
  if slot >= 0 then
    for j = 0, 31 do
      for i = 0, 1 do
        sspr(i*64, slot*32 + j, 64, 1, x-w/2, y-w/2+j*2+i)
      end
    end
  end
end

function draw_cart(x, y, slot)
  local w=64

  -- border
  rectfill(x-w/2-2, y-w/2-11, x+w/2+2, y+w/2+2, 5)
  -- rectfill(x-w/2-2, y+w/2+7, x+w/2-5, y+w/2+13, 5)

  -- corner
  -- line(x+w/2+1, y+w/2+6, x+w/2-4, y+w/2+11, 7)
  -- line(x+w/2+1, y+w/2+7, x+w/2-4, y+w/2+12, 7)
  -- line(x+w/2+1, y+w/2+8, x+w/2-4, y+w/2+13, 7)

  -- TODO waste of tokens
  for i=0,10 do
    line(x-w/2-2, y+w/2+3+i, x+w/2+2-max(i-3, 0), y+w/2+3+i, 5)
    if i <= 8 then
      line(x-w/2, y+w/2+3+i, x+w/2-max(i-2, 0), y+w/2+3+i, 13)
    end
  end

  -- divet
  rectfill(x-w/2, y-w/2-9, x+w/2, y-w/2-3, 13)
  -- rectfill(x-w/2, y+w/2+3, x+w/2, y+w/2+11, 13)

  -- pico8 logo
  spr(128, x-w/2+1, y-w/2-8, 5, 1)

  -- edge connector
  for i=0,9 do
    rect(x-w/2+4+5*i, y+w/2+5, x-w/2+5+5*i, y+w/2+13, 9)
    rect(x-w/2+6+5*i, y+w/2+5, x-w/2+6+5*i, y+w/2+13, 10)
  end

  -- label
  draw_label(x, y, w, slot)
end

cart_y_ease=0
cart_y_bob=0
cart_x_swipe=64
-- 1 is up, -1 is down
cart_tween_state=1

cart_tween={}
cart_swipe_tween={}
cart_bobble_tween={}

function cart_tween_bobble()
  bob_amplitude=2
  cart_bobble_tween=tween_machine:add_tween({
    func=inOutSine,
    v_start=-bob_amplitude,
    v_end=bob_amplitude,
    duration=1
  })
  cart_bobble_tween:register_step_callback(function(pos)
    cart_y_bob=pos
  end)
  cart_bobble_tween:register_finished_callback(function(tween)
    tween.v_start=tween.v_end 
    tween.v_end=-tween.v_end
    tween:restart()
  end)
  cart_bobble_tween:restart()
end

function cart_tween_down()
  cart_tween=tween_machine:add_tween({
    func=outQuart,
    v_start=cart_y_ease,
    v_end=90,
    duration=1
  })
  cart_tween:register_step_callback(function(pos)
    cart_y_ease=pos
  end)
  cart_tween:register_finished_callback(function(tween)
    tween:remove()
  end)
  cart_tween:restart()
end

function cart_tween_up()
  cart_tween=tween_machine:add_tween({
    func=outQuart,
    v_start=cart_y_ease,
    v_end=0,
    duration=1
  })
  cart_tween:register_step_callback(function(pos)
    cart_y_ease=pos
  end)
  cart_tween:register_finished_callback(function(tween)
    tween:remove()
    cart_tween_bobble()
  end)
  cart_tween:restart()
end

-- dir is -1 (left) or 1 (right)
function make_cart_swipe_tween(dir)
  cart_swipe_tween=tween_machine:add_tween({
    func=outQuart,
    v_start=64,
    v_end=64+dir*128,
    duration=0.25
  })
  cart_swipe_tween:register_step_callback(function(pos)
    cart_x_swipe=pos
  end)
  cart_swipe_tween:register_finished_callback(function(tween)
    cart_x_swipe=64-1*dir*128
    tween:remove()
    load_label(carts:cur(), 0)
    make_cart_swipe_tween_2(dir)
  end)
  cart_swipe_tween:restart()
end

-- part 2 of tween
function make_cart_swipe_tween_2(dir)
  cart_swipe_tween=tween_machine:add_tween({
    func=outQuart,
    v_start=64-1*dir*128,
    v_end=64,
    duration=0.25
  })
  cart_swipe_tween:register_step_callback(function(pos)
    cart_x_swipe=pos
  end)
  cart_swipe_tween:register_finished_callback(function(tween)
    tween:remove()
  end)
  cart_swipe_tween:restart()
end

transition_radius=0
transition_tween={}
function make_transition_tween(cart)
  transition_tween=tween_machine:add_tween({
    func=outQuart,
    v_start=0,
    v_end=200,
    duration=1
  })
  transition_tween:register_step_callback(function(pos)
    transition_radius=pos
  end)
  transition_tween:register_finished_callback(function(tween)
    tween:remove()
    load(cart_dir .. '/' .. tostring(cart.filename) .. '.p8', 'back to games')
  end)
  transition_tween:restart()
end

function _init()
  -- setup dual palette
  --poke(0x5f5f,0x10)
  --for i=0,15 do pal(i,i+128,2) end
  ----memset(0x5f78,0xff,8)

  serial_hello()

  carts=menu_new(serial_ls(cart_dir))
  labels=ls(label_dir)
  for cart in all(carts.items) do
    printh(tostring(cart))
  end

  cart_tween_bobble()

  load_label(carts:cur(), 0)
end

function _update60()
  tween_machine:update()

  if cart_tween_state > 0 then
    if btnp(0) then
      sfx(0)
      carts:up()
      make_cart_swipe_tween(1)
    elseif btnp(1) then
      sfx(0)
      carts:down()
      make_cart_swipe_tween(-1)
    elseif btnp(5) then
      sfx(2)
      cart_bobble_tween:remove()
      cart_tween_down()
      cart_tween_state = -1
    end
  else
    if btnp(2) then
      sfx(0)
      cart_options:up()
    elseif btnp(3) then
      sfx(0)
      cart_options:down()
    elseif btnp(4) then
      sfx(3)
      cart_bobble_tween:remove()
      cart_tween_up()
      cart_tween_state = 1
    elseif btnp(5) then
      cart_options:cur().func()
    end
  end
end

function draw_menuitem(w, y, text, sel)
  if sel then c=7 else c=6 end
  local h=12
  rectfill(0, y, w, y+h, 13)
  line(0, y-1, w, y-1, c)
  line(w+1, y, w+1, y+h-1, c)
  line(0, y+h, w, y+h, c)
  print(text, w-#text*4-3, y+4, c)
end

function _draw()
  cls(bg_color)

  -- draw the cartridge
  -- draw_cart(-16, 64.5, -1)
  -- draw_cart(128+16, 64.5, -1)
  draw_cart(cart_x_swipe, 64.5+cart_y_ease+cart_y_bob, 0)
  str="❎view"
  print(str, 64-#str*2, 117+cart_y_ease+cart_y_bob, 7)
  if cart_tween_state > 0 then
    print("⬅️", 3, 64, 7)
    print("➡️", 118, 64, 7)
  end

  menu_x=36
  menu_y=-10
  print(tostring(carts:cur().name), menu_x, -(#cart_options.items*7)+menu_y-10+cart_y_ease, 14)
  print('by ' .. tostring(carts:cur().author), menu_x, -(#cart_options.items*7)+menu_y-3+cart_y_ease, 15)
  line_y=-(#cart_options.items*7)+menu_y+3+cart_y_ease
  line(menu_x, line_y, 88, line_y, 6)
  for i, menuitem in ipairs(cart_options.items) do
    is_sel=cart_options:index() == i
    if is_sel then
      c=7
      x_off=0
    else
      c=6
      x_off=2
    end
    print(menuitem.label, menu_x+x_off, -(#cart_options.items*7)+menu_y+i*7+cart_y_ease, c)
  end

  -- selection menu
  -- for i, cart in ipairs(carts.items) do
  --   is_sel=carts:index() == i
  --   if is_sel then w=60 else w=50 end
  --   draw_menuitem(w, 10+15*i, tostring(cart.name), is_sel)
  -- end
  -- print(carts.select)

  -- top bar
  rectfill(0, 0, 128, 8, bar_color_1)
  print("★", 2, 2, 10)
  print("my games", 12, 2, 7)


  --for i=0,#carts do
  --end

  -- transition
  circfill(64, 128, transition_radius, 0)
end

__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00800007777077770077700777700000777700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
097f0077077007700770007707700000700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
a777e077777007700770007707707707777700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0b7d0077000007700770007707700007700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00c00077000077770777707777000007777700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
000200000d7500d7500d7000840008400084000c4000c4000c4000b40012400074000a40008400034000630000000000000000000000000000000000000000000000000000000000000000000000000000000000
000600000432004320000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00010000015500655008550095500a5500b5500c5500d5500e5500f5501155012550135501455017550195501c5501f550235002450022500215001f5001e5001d5001b500195001650014500145001250011500
000100001a5501a5501855017550155501255012550105500d5500a55007550055500555004550035500155000550000000000000000000000000000000000000000000000000000000000000000000000000000

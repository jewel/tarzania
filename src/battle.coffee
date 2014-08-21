canvas = document.getElementById( 'arena' )

canvas.width = 2500
canvas.height = 1200

ctx = canvas.getContext('2d')

socket = null

last_received = null

name = "foo"

color = "000"

timer = false

gravity = 0.25

world = {
  w: 50000
}

class Rope
  constructor: (x, y, length) ->
    @pos = new Vector x, y
    @vector = new Vector(random_int(length)/4-length/2, -length)
    @velocity = new Vector 0, 0

class Bullet
  constructor: (x, y, velocity) ->
    @pos = new Vector(x, y)
    @velocity = velocity.clone()

our_size = 5
pos = new Vector 25, 1100
velocity = new Vector 10, 0
clutch = null
clutch_len = null

ropes = []

random_int = (max) ->
  Math.floor( Math.random() * max )

rope_count = 50
while rope_count > 0
  rope_count--
  ropes.push new Rope( random_int(world.w), 1200, random_int(400) + 700 )

texture_count = 150
textures = []
while texture_count > 0
  texture_count--
  textures.push
    pos:
      x: random_int( world.w )
      y: random_int( 1200 )
    size: random_int( 400 ) + 100
    color: "rgb( #{random_int(64)+191}, #{random_int(64)+191}, #{random_int(64)+191} )"

bullets = []

reconnect = ->
  socket = io.connect window.location.href

  last_received = new Date().getTime() + 10000

  socket.on 'update', (obj) ->
    last_received = new Date().getTime()

  socket.on 'connect', ->
    last_received = new Date().getTime() + 5000

    if !timer
       window.setInterval change_state, 15

    timer = true

reconnect()

draw = ->
  ctx.save()
  ctx.fillStyle = '#fff'
  ctx.fillRect 0, 0, canvas.width, canvas.height

  scroll_offset = canvas.width / 4 - pos.x


  ctx.save()
  for t in textures
    ctx.beginPath()
    ctx.arc(t.pos.x + scroll_offset, canvas.height - t.pos.y, t.size, 0, Math.PI*2, false)
    ctx.closePath()
    ctx.fillStyle = t.color
    ctx.fill()
  ctx.restore()

  ctx.save()
  ctx.lineWidth = 2
  for r in ropes
    ctx.beginPath()
    ctx.moveTo r.pos.x + scroll_offset, canvas.height - r.pos.y
    end = r.pos.plus r.vector
    ctx.lineTo( end.x + scroll_offset, canvas.height - end.y )
    ctx.stroke()
  ctx.restore()

  ctx.save()
  ctx.lineWidth = 2
  for b in bullets
    ctx.beginPath()
    ctx.moveTo b.pos.x + scroll_offset, canvas.height - b.pos.y
    end = b.pos.plus b.velocity.normalized().times(16)
    ctx.lineTo( end.x + scroll_offset, canvas.height - end.y )
    ctx.stroke()
  ctx.restore()

  ctx.beginPath()
  ctx.arc(pos.x + scroll_offset, canvas.height - pos.y, our_size, 0, Math.PI*2, false)
  ctx.closePath()
  ctx.stroke()
  ctx.fillStyle = "##{color}"
  ctx.fill()

  ctx.restore()

keys_pressed = {}

mouse_pressed = false

reload = 0

window.onkeydown = (e) ->
  keys_pressed[e.which] = true
  e.which != 32 && ( e.which < 37 || e.which > 40 )

window.onkeyup = (e) ->
  keys_pressed[e.which] = false
  e.which != 32 && ( e.which < 37 || e.which > 40 )

window.onmousedown = (e) ->
  mouse_pressed = true
  false

window.onmouseup = (e) ->
  mouse_pressed = false
  false

mouse_position = null

document.onmousemove = (e) ->
  mouse_position = e

change_state = ->
  if !clutch && keys_pressed[32]
    for r in ropes
      closest = pos.intersection r.pos, r.pos.plus( r.vector )
      continue unless closest
      continue if pos.distance( closest ) > our_size + velocity.length()
      r.velocity.mult 0.5
      r.velocity.add velocity
      clutch_len = pos.distance r.pos
      clutch = r
      break

  if clutch
    velocity = clutch.velocity.clone()

  if clutch && !keys_pressed[32]
    velocity.add clutch.velocity.normalized().times(10)
    clutch = null

  if keys_pressed[70]
    poo = velocity.plus velocity.normalized().times(20)
    if poo.x < 0
      poo.mult(-1)

    b = new Bullet(pos.x, pos.y, poo)
    bullets.push b

  if keys_pressed[68]
    poo = velocity.plus velocity.normalized().times(20)
    if poo.x > 0
      poo.mult(-1)
    velocity.sub poo.times(0.01)

    b = new Bullet(pos.x, pos.y, poo)
    bullets.push b

  # gravity
  velocity.y -= gravity

  for r in ropes
    v = r.velocity
    v.y -= gravity
    projection_magnitude = v.dot r.vector.normalized()
    # velocity parallel to rope
    projection = r.vector.normalized().times(projection_magnitude)
    v.sub projection
    r.vector.add v

  for b in bullets
    b.velocity.y -= gravity
    b.pos.add b.velocity

  if clutch
    pos = clutch.pos.plus clutch.vector.normalized().times( clutch_len )
  else
    pos.add velocity

  if pos.x < 0
     pos.x = 0
     velocity.x = -velocity.x
     velocity.mult(0.75)

  if pos.y < 0
     pos.y = 0
     velocity.y = -velocity.y
     velocity.mult(0.75)

  if pos.x > world.w
     pos.x = world.w
     velocity.x = -velocity.x
     velocity.mult(0.75)

  socket.emit 'update'
    pos: pos
    name: name

  time_diff = new Date().getTime() - last_received

  if time_diff > 250
    reconnect()

  draw()

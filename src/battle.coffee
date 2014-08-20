canvas = document.getElementById( 'arena' )

ctx = canvas.getContext('2d')

socket = null

last_received = null

name = "foo"

color = "000"

timer = false

class Rope
  constructor: (x, y, length) ->
    @pos = new Vector x, y
    @vector = new Vector 0, -length
    @velocity = new Vector 0, 0

our_size = 5
pos = new Vector 25, 500
velocity = new Vector 5, 0
clutch = null
clutch_len = null

ropes = [
  new Rope( 100, 600, 400 )
  new Rope( 300, 600, 250 )
  new Rope( 400, 600, 450 )
  new Rope( 600, 600, 550 )
  new Rope( 950, 600, 450 )
]

reconnect = ->
  socket = io.connect window.location.href

  last_received = new Date().getTime() + 10000

  socket.on 'update', (obj) ->
    last_received = new Date().getTime()

  socket.on 'connect', ->
    last_received = new Date().getTime() + 5000

    if !timer
       window.setInterval change_state, 30

    timer = true

reconnect()

draw = ->
  ctx.save()
  ctx.fillStyle = '#fff'
  ctx.fillRect 0, 0, canvas.width, canvas.height

  ctx.save()
  ctx.lineWidth = 2
  for r in ropes
    ctx.beginPath()
    ctx.moveTo r.pos.x, canvas.height - r.pos.y
    end = r.pos.plus r.vector
    ctx.lineTo( end.x, canvas.height - end.y )
    ctx.stroke()
  ctx.restore()

  ctx.beginPath()
  ctx.arc(pos.x, canvas.height - pos.y, our_size, 0, Math.PI*2, false)
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
      closest = pos.intersection( r.pos, r.pos.plus( r.vector ) )
      continue unless closest
      continue if pos.distance( closest ) > our_size + velocity.length()
      r.velocity = velocity.clone()
      clutch_len = pos.distance r.pos
      clutch = r

  if clutch && !keys_pressed[32]
    velocity = clutch.velocity.clone()
    clutch = null

  # gravity
  velocity.y -= 0.5

  for r in ropes
    v = r.velocity
    v.y -= 0.5
    projection_magnitude = v.dot r.vector.normalized()
    # velocity parallel to rope
    projection = r.vector.normalized().mult(projection_magnitude)
    v.sub projection
    r.vector.add v

  if clutch
    pos = clutch.pos.plus( clutch.vector.normalized().mult( clutch_len ) )
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

  if pos.x > canvas.width
     pos.x = canvas.width
     velocity.x = -velocity.x
     velocity.mult(0.75)

  socket.emit 'update'
    pos: pos
    name: name

  time_diff = new Date().getTime() - last_received

  if time_diff > 250
    reconnect()

  draw()

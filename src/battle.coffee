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
    @velocity = 0

our_size = 5
pos = new Vector 25, 500
velocity = new Vector 5, 0
clutch = null
clutch_len = 0

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
      clutch = r
      r.velocity = velocity.length()
      if velocity.x < 0
        r.velocity = -r.velocity
      velocity.x = 0
      velocity.y = 0
      clutch_len = pos.distance r.pos

  if clutch && !keys_pressed[32]
    r = clutch
    velocity.x = r.vector.y
    velocity.y = -r.vector.x
    velocity.normalize().mult(-r.velocity)
    clutch = null

  if clutch
    pos = clutch.pos.plus( clutch.vector.normalized().mult( clutch_len ) )
  else
    # gravity
    velocity.y -= 0.5
    pos.add( velocity )


  for r in ropes
    v = r.vector
    l = v.length()
    v.x += r.velocity
    v.normalize()
    if Math.abs(v.y) < 0.4
      r.velocity = -r.velocity
    v.mult(l)

  if pos.x < 0
     pos.x = 0
     velocity.x = -velocity.x
     velocity.mult(0.75)

  if pos.y < 0
     pos.y = 0
     velocity.y = -velocity.y
     velocity.mult(1.0)

  if pos.x > canvas.width
     pos.x = canvas.width
     velocity.x = -velocity.x
     velocity.mult(0.75)

  reload-- if reload > 0

  bullet = null

  if mouse_pressed && mouse_position && reload == 0
    dir = new Vector( mouse_position.clientX + window.scrollX - canvas.offsetLeft,
                      mouse_position.clientY + window.scrollY - canvas.offsetTop )
    dir.sub(pos)
    dir.normalize()
    dir.mult( 10 )

    bullet =
      pos: pos.plus(dir)
      dir: dir

    reload = 3

  socket.emit 'update'
    pos: pos
    bullet: bullet
    name: name

  time_diff = new Date().getTime() - last_received

  if time_diff > 250
    reconnect()

  draw()

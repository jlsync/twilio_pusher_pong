BAT_ACCELERATION = 10 # 0.40
BAT_TERMINAL_VELOCITY = 5
BAT_FRICTION = 0.10
BALL_ACCELERATION = 5
BALL_TERMINAL_VELOCITY = 5
BALL_FRICTION = 0
LEFT = 0
RIGHT = 1

class Entity
  x: 0, y: 0, vx: 0, vy: 0 
  constructor: (@context, @maxX, @maxY, @minX, @minY, @offsetX, @offsetY, @a, @tv, @f) ->
    @score = 0

  score_plus_one: -> @score += 1

  getScore: -> @score

  update: ->
    # Apply friction
    @vx -= @f if @vx > 0
    @vx += @f if @vx < 0
    @vy -= @f if @vy > 0
    @vy += @f if @vy < 0

    # Make sure we dont go faster than terminal velocity
    @vx = @tv if @vx > @tv
    @vx = -@tv if @vx < -@tv
    @vy = @tv if @vy > @tv
    @vy = -@tv if @vy < -@tv

    # Update the entitys co-ordinates
    @x += @vx
    @y += @vy

    @checkBoundary()
  
  checkBoundary: ->
    @x = @maxX-@w if @x+@w > @maxX
    @x = @minX if @x < @minX
    @y = @maxY-@h if @y+@h > @maxY
    @y = @minY if @y < @minY

  draw: ->
    @context.fillStyle = 'rgba(0,0,0,0.8)'
    @context.fillRect @x+@offsetX, @y+@offsetY, @w, @h

  accelX: -> @vx += @a
  accelY: -> @vy += @a
  decelX: -> @vx -= @a
  decelY: -> @vy -= @a

  up: ->
    @vy -= @a
  down: ->
    @vy += @a

class Bat extends Entity
  w: 40, h: 175,  side: LEFT

  setName: (name) -> @name = name
  getName:  -> @name || "unknown"
  setSide: (side) ->
    @side = side
    if side is LEFT
      @offsetX = 30
    else
      @offsetX = pong.canvas.width - 70

  getSide: -> @side

  draw: ->
    super()
    if @getSide() is LEFT
      @context.fillText(@getName(), @x+@offsetX+@w,  @y+@offsetY + (@h /2 ))
    else
      @context.fillText(@getName(), @x+@offsetX - 150 ,  @y+@offsetY + (@h /2 ))

class Ball extends Entity
  w: 40, h: 40, x: 200, y: 200, game_over: false

  checkGameOver: -> @game_over

  checkBoundary: ->
    if @x+@w > @maxX
      @game_over = true
    if @x < @minX
      @game_over = true

    # If we hit the top or the bottom we need to bounce
    @vy = -@vy if @y+@h > @maxY or @y < @minY
  
  checkCollision: (e ) ->
    x = @x + @offsetX
    y = @y + @offsetY
    ex = e.x + e.offsetX
    ey = e.y + e.offsetY
    if y >= ey and y <= ey+e.h
      if e.side is LEFT and x < ex+e.w
        @x += BAT_TERMINAL_VELOCITY / 2
        @vx = -@vx
        e.score_plus_one()
      if e.side is RIGHT and x+@w > ex
        @x -= BAT_TERMINAL_VELOCITY / 2
        @vx = -@vx
        e.score_plus_one()

  draw: ->
    @context.fillStyle = 'rgba(0,0,0,0.8)'
    @context.fillRect @x+@offsetX, @y+@offsetY, @w, @h
  
class PongApp
  main: ->
    @createCanvas()
    @addKeyObservers()
    @startNewGame()

    @players = []
    @bat1 = new Bat @context, @canvas.width, @canvas.height, 0, 0, 30, 0, BAT_ACCELERATION, BAT_TERMINAL_VELOCITY, BAT_FRICTION
    @bat1.setName('bat1')
    @bat1.setSide(LEFT)

    @bat2 = new Bat @context, @canvas.width, @canvas.height, 0, 0, @canvas.width - 70, 0, BAT_ACCELERATION, BAT_TERMINAL_VELOCITY, BAT_FRICTION
    @bat2.setName('bat2')
    @bat2.setSide(RIGHT)

    @addPlayer(@bat1)
    @addPlayer(@bat2)

  newPlayer: (name) ->
    np =  new Bat @context, @canvas.width, @canvas.height, 0, 0, 30, 0, BAT_ACCELERATION, BAT_TERMINAL_VELOCITY, BAT_FRICTION
    np.setName(name)
    lc = 0
    rc = 0
    for p in @players
      if p.getSide() is LEFT then lc += 1 else rc += 1
    if lc > rc then np.setSide(RIGHT) else np.setSide(LEFT)
    @addPlayer(np)
    np

  addPlayer: (player) ->
    @players.push(player)

  startNewGame: ->

    @ball = new Ball @context, @canvas.width, @canvas.height, 0, 0, 0, 0, BALL_ACCELERATION, BALL_TERMINAL_VELOCITY, BALL_FRICTION
    
    @ball.vx = 5
    @ball.vy = 5

    
    @run_game()
  
  run_game: ->
    @interval_id = setInterval =>

      # Update position of players
      p.update() for p in @players
      # Update position of ball
      @ball.update()

      # Check for ball collsions with bats
      @ball.checkCollision(p) for p in @players

      # Check for winner
      if @ball.checkGameOver()
        @terminateRunLoop = true
        @notifyCurrentUser "Game Over! Scores:<br/>#{("#{p.getName()}: #{p.getScore()}<br/>" for p in @players).join("")}<br/> New game starting in 3 seconds."
        setTimeout =>
          @notifyCurrentUser ''
          @terminateRunLoop = false
          @startNewGame()
        , 3000

      # Clear the Canvas
      @clearCanvas()
    
      # Redraw game entities
      p.draw() for p in @players
      @ball.draw()

      # Run again unless we have been killed
      clearInterval(@interval_id) if @terminateRunLoop
    , 20

  notifyCurrentUser: (message) ->
    document.getElementById('message').innerHTML = message

  # Run when the game is quit to clean up everything we create
  cleanup: ->
    @terminateRunLoop = true
    @clearCanvas()

  # Creates an overlay for the sceen and a canvas to draw the game on
  createCanvas: ->
    @canvas = document.getElementById 'canvas'
    @context = @canvas.getContext '2d'
    @canvas.width = document.width
    @canvas.height = document.height
    @context.font      = "normal 36px Verdana"
    @context.fillStyle = "#000000"

  clearCanvas: ->
    @context.clearRect 0, 0, @canvas.width, @canvas.height

  addKeyObservers: ->
    document.addEventListener 'keydown', (e) =>
      switch e.keyCode
        when 40 then @bat2.down()
        when 38 then @bat2.up()
        when 90 then @bat1.down()
        when 65 then @bat1.up()
    , false

pong = new PongApp

$ = jQuery

window.Bat = Bat
window.PongApp = PongApp
window.Ball = Ball
window.pong = pong

$ ->
  pong.main()

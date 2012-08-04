BAT_ACCELERATION = 9 # 0.40
BAT_TERMINAL_VELOCITY = 5
BAT_FRICTION = 0.10
BALL_ACCELERATION = 5
BALL_TERMINAL_VELOCITY = 5
BALL_FRICTION = 0
LEFT = 0
RIGHT = 1

class Entity
  x: 0, y: 0, vx: 0, vy: 0, r: 0, g: 0, b: 0
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
    @context.fillStyle = "rgba(#{@r},#{@g},#{@b},0.8)"
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


  randColor: ->
    @r = "#{parseInt((Math.random() * 240),10)}"
    @g = "#{parseInt((Math.random() * 240),10)}"
    @b = "#{parseInt((Math.random() * 240),10)}"

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
      @context.fillText(@getName(), @x+@offsetX - 200 ,  @y+@offsetY + (@h /2 ))

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

    @players = {}
    @bat1 = new Bat @context, @canvas.width, @canvas.height, 0, 0, 30, 0, BAT_ACCELERATION, BAT_TERMINAL_VELOCITY, BAT_FRICTION
    @bat1.setName('bat1')
    @bat1.setSide(LEFT)

    @bat2 = new Bat @context, @canvas.width, @canvas.height, 0, 0, @canvas.width - 70, 0, BAT_ACCELERATION, BAT_TERMINAL_VELOCITY, BAT_FRICTION
    @bat2.setName('bat2')
    @bat2.setSide(RIGHT)

    #OFF @addPlayer(@bat1)
    #OFF @addPlayer(@bat2)

  move: (from: from, digit: digit) ->
    @newPlayer(from) if not @players[from]
    if digit is "4"
      @players[from].up()
    else if digit is "6"
      @players[from].down()

  player_leave: (from: from) ->
    delete @players[from]


  newPlayer: (name) ->
    np =  new Bat @context, @canvas.width, @canvas.height, 0, 0, 30, 0, BAT_ACCELERATION, BAT_TERMINAL_VELOCITY, BAT_FRICTION
    np.setName(name)
    np.randColor()
    lc = 0
    rc = 0
    count = 0
    for name, p of @players
      count += 1
      if p.getSide() is LEFT then lc += 1 else rc += 1
    if lc > rc then np.setSide(RIGHT) else np.setSide(LEFT)
    @addPlayer(np)
    height = if count < 3
              @canvas.height / 4
             else if  count < 5
              @canvas.height / 5
             else
              @canvas.height / 6

    for name, p of @players
      p.h = parseInt(height,10)

    np

  addPlayer: (player) ->
    @players[player.getName()] = player

  startNewGame: ->

    @ball = new Ball @context, @canvas.width, @canvas.height, 0, 0, 0, 0, BALL_ACCELERATION, BALL_TERMINAL_VELOCITY, BALL_FRICTION
    
    @ball.vx = 5
    @ball.vy = 5

    
    @run_game()
  
  run_game: ->
    @interval_id = setInterval =>

      # Update position of players
      p.update() for name,p of @players
      # Update position of ball
      @ball.update()

      # Check for ball collsions with bats
      @ball.checkCollision(p) for name,p of @players

      # Check for winner
      if @ball.checkGameOver()
        @terminateRunLoop = true
        @notifyCurrentUser "Game Over! Scores:<br/>#{("#{p.getName()}: #{p.getScore()}<br/>" for name, p of @players).join("")}<br/> New game starting in 3 seconds."
        setTimeout =>
          @notifyCurrentUser ''
          @terminateRunLoop = false
          @startNewGame()
        , 3000

      # Clear the Canvas
      @clearCanvas()
    
      # Redraw game entities
      p.draw() for name, p of @players
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
    @canvas.width = document.width - 30
    @canvas.height = document.height - 30
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

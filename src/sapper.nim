import cart/wasm4
import std/random

const WIDTH = 16
const HEIGHT = WIDTH
const CELL_WIDTH = SCREEN_SIZE div WIDTH
const CELL_HEIGHT = SCREEN_SIZE div HEIGHT
const MINES = 40

type GameState = enum IN_PROGRESS, OVER
var gameState: GameState = IN_PROGRESS

### Field

# for a cell: 
# open: 0-8 - number of surrounding mines
# closed: 10 - empty, 11 - mine
const HIDDEN_MINE = 11
const UNKNOWN = 10
var field: array[WIDTH, array[HEIGHT, uint8]]

proc generateField = 
  for x in 0..WIDTH:
    for y in 0..HEIGHT:
      field[x][y] = UNKNOWN

  var minesLeft = MINES
  while minesLeft > 0:
    let mineX = rand(WIDTH)
    let mineY = rand(HEIGHT)
    if field[mineX][mineY] == UNKNOWN:
      field[mineX][mineY] = HIDDEN_MINE
      minesLeft -= 1   

proc surroundingMines(x: int, y: int): uint8 =
  uint8(x > 0 and y > 0 and field[x-1][y-1] == HIDDEN_MINE) + 
  uint8(x > 0 and field[x-1][y] == HIDDEN_MINE) + 
  uint8(x > 0 and y < HEIGHT - 1 and field[x-1][y+1] == HIDDEN_MINE) + 
  uint8(y > 0 and field[x][y-1] == HIDDEN_MINE) + 
  uint8(y < HEIGHT-1 and field[x][y+1] == HIDDEN_MINE) + 
  uint8(x < WIDTH-1 and y > 0 and field[x+1][y-1] == HIDDEN_MINE) + 
  uint8(x < WIDTH-1 and field[x+1][y] == HIDDEN_MINE) + 
  uint8(x < WIDTH-1 and y < HEIGHT-1 and field[x+1][y+1] == HIDDEN_MINE)

proc maybeOpenCell(x: int, y: int) =
  case field[x][y]
    of HIDDEN_MINE:
      gameState = OVER
    of UNKNOWN:
      field[x][y] = surroundingMines(x, y)
    of 0..8:
      discard # TODO  
    else:
      discard

### Sapper

var sapperX: int 
var sapperY: int

proc moveSapper(x: int, y: int) =
  sapperX = x
  sapperY = y
  maybeOpenCell(x,y)

proc mayBeMoveSapper(keyPressed: uint8) =
  if bool(keyPressed and BUTTON_LEFT):
    moveSapper(max(0, sapperX - 1), sapperY)
  elif bool(keyPressed and BUTTON_RIGHT):
    moveSapper(min(WIDTH - 1, sapperX + 1), sapperY)
  elif bool(keyPressed and BUTTON_UP):
    moveSapper(sapperX, max(0, sapperY - 1))
  elif bool(keyPressed and BUTTON_DOWN):
    moveSapper(sapperX, min(HEIGHT - 1, sapperY + 1))

### Game state

proc restart =
  gameState = IN_PROGRESS
  generateField()
  moveSapper(rand(WIDTH), rand(HEIGHT))

### Drawing

proc drawSapper(x: int, y: int) = 
  DRAW_COLORS[] = 0x4
  oval(x * CELL_WIDTH + 2, y * CELL_HEIGHT + 2, CELL_WIDTH - 4, CELL_HEIGHT - 4)

proc drawUnknownCell(x: int, y: int) =
  DRAW_COLORS[] = 0x23
  rect(x * CELL_WIDTH, y * CELL_HEIGHT, CELL_WIDTH, CELL_HEIGHT)

proc drawCell(x: int, y: int) = 
  case field[x][y]
    of UNKNOWN:
      drawUnknownCell(x, y)
    of HIDDEN_MINE:
      if gameState == OVER:
        DRAW_COLORS[] = 0x23
        oval(x * CELL_WIDTH + 2, y * CELL_HEIGHT + 2, CELL_WIDTH - 4, CELL_HEIGHT - 4)
      else:
        drawUnknownCell(x, y)
    of 0..8:
      DRAW_COLORS[] = 0x4
      text($field[x][y], x * CELL_WIDTH + 1, y * CELL_HEIGHT + 1)
    else:
      discard  

proc drawField =
  for x in 0..WIDTH:
    for y in 0..HEIGHT:
      drawCell(x,y)

proc drawGameOver =
  DRAW_COLORS[] = 0x24
  text("Game over", SCREEN_SIZE div 2 - 9*4, SCREEN_SIZE div 2 - 5)
  text("Press x to restart", SCREEN_SIZE div 2 - 18*4, SCREEN_SIZE div 2 + 5)

### Setup and update

proc setup =
  PALETTE[0] = 0xE0F8CF
  PALETTE[1] = 0x86C06C
  PALETTE[2] = 0x306850
  PALETTE[3] = 0xFF0000
  restart()

# Call NimMain so that global Nim code in modules will be called, 
# preventing unexpected errors
proc NimMain {.importc.}

proc start {.exportWasm.} = 
  NimMain()
  # https://github.com/aduros/wasm4/issues/734
  #randomize()
  setup()

var previousGamepad: uint8

proc update {.exportWasm.} =
  var gamepad = GAMEPAD1[]
  let keyPressed = gamepad and (gamepad xor previousGamepad)

  if bool(keyPressed and BUTTON_1):
    restart()
  elif gameState == IN_PROGRESS and keyPressed != 0:
    mayBeMoveSapper(keyPressed)
  
  drawField()
  drawSapper(sapperX, sapperY) 
  if (gameState == OVER):
    drawGameOver()
  
  # must be at the end to avoid false updates
  previousGamepad = gamepad


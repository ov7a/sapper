import cart/wasm4
import std/random

type GameState = enum START, IN_PROGRESS, OVER, VICTORY
var gameState: GameState = START

### Field

type
  CellValue = uint8
  Coord = int # good luck changing this to int8
  Cell = (Coord, Coord)

const 
  WIDTH: Coord = 16
  HEIGHT: Coord = WIDTH
  FIELD_SIZE: int = WIDTH * HEIGHT
  MINES = 40

# for a cell: 
# open: 0-8 - number of surrounding mines
# closed: 10 - empty, 11 - mine
const 
  HIDDEN_MINE = 11
  UNKNOWN = 10

var 
  field: array[WIDTH, array[HEIGHT, CellValue]]
  closedCells = FIELD_SIZE

proc isSolvable: bool =
  static: assert WIDTH*HEIGHT <= 1 shl sizeof(uint8)
  var visited: set[uint8]
  proc pos(p: Cell): uint8 = uint8(p[0] * WIDTH + p[1])

  iterator neighbors(p: Cell): Cell =
    let (x, y) = p
    if (x > 0): yield (x - 1, y)
    if (x < WIDTH - 1): yield (x + 1, y)
    if (y > 0): yield (x, y - 1)
    if (y < HEIGHT - 1): yield (x, y + 1)

  var stack: seq[Cell] = @[(WIDTH div 2, HEIGHT div 2)]

  while stack.len > 0:
    let current = stack.pop()
    visited.incl(current.pos())
    for neighbor in neighbors(current):
      if (not (neighbor.pos() in visited)) and field[neighbor[0]][neighbor[1]] != HIDDEN_MINE:
        stack.add(neighbor)

  visited.len == FIELD_SIZE - MINES     

proc generateField(startX: Coord, startY: Coord) = 
  while true:
    for x in 0..<WIDTH:
      for y in 0..<HEIGHT:
        field[x][y] = UNKNOWN

    var minesLeft = MINES
    while minesLeft > 0:
      let mineX = rand(WIDTH - 1)
      let mineY = rand(HEIGHT - 1)
      if field[mineX][mineY] == UNKNOWN and (mineX != startX or mineY != startY):
        field[mineX][mineY] = HIDDEN_MINE
        minesLeft -= 1     

    if (isSolvable()):
      break

proc surroundingMines(x: Coord, y: Coord): uint8 =
  uint8(x > 0 and y > 0 and field[x-1][y-1] == HIDDEN_MINE) + 
  uint8(x > 0 and field[x-1][y] == HIDDEN_MINE) + 
  uint8(x > 0 and y < HEIGHT - 1 and field[x-1][y+1] == HIDDEN_MINE) + 
  uint8(y > 0 and field[x][y-1] == HIDDEN_MINE) + 
  uint8(y < HEIGHT-1 and field[x][y+1] == HIDDEN_MINE) + 
  uint8(x < WIDTH-1 and y > 0 and field[x+1][y-1] == HIDDEN_MINE) + 
  uint8(x < WIDTH-1 and field[x+1][y] == HIDDEN_MINE) + 
  uint8(x < WIDTH-1 and y < HEIGHT-1 and field[x+1][y+1] == HIDDEN_MINE)

proc maybeOpenCell(x: Coord, y: Coord) =
  case field[x][y]
    of HIDDEN_MINE:
      gameState = OVER
    of UNKNOWN:
      field[x][y] = surroundingMines(x, y)
      closedCells -= 1
      if (closedCells == MINES):
        gameState = VICTORY
    else:
      discard

### Sapper

var 
  sapperX: Coord
  sapperY: Coord

proc moveSapper(x: Coord, y: Coord) =
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
  closedCells = FIELD_SIZE
  let 
    startX = Coord(rand(WIDTH-1))
    startY = Coord(rand(HEIGHT-1))
  generateField(startX, startY)
  moveSapper(startX, startY)
  gameState = IN_PROGRESS

### Drawing

const 
  CELL_WIDTH = SCREEN_SIZE div WIDTH
  CELL_HEIGHT = SCREEN_SIZE div HEIGHT

proc drawSapper(x: Coord, y: Coord) = 
  DRAW_COLORS[] = 0x4
  oval(x * CELL_WIDTH + 3, y * CELL_HEIGHT + 3, CELL_WIDTH - 6, CELL_HEIGHT - 6)

proc drawUnknownCell(x: Coord, y: Coord) =
  DRAW_COLORS[] = 0x23
  rect(x * CELL_WIDTH, y * CELL_HEIGHT, CELL_WIDTH, CELL_HEIGHT)

proc drawCell(x: Coord, y: Coord) = 
  case field[x][y]
    of UNKNOWN:
      drawUnknownCell(x, y)
    of HIDDEN_MINE:
      if gameState == OVER:
        DRAW_COLORS[] = 0x23
        oval(x * CELL_WIDTH + 2, y * CELL_HEIGHT + 2, CELL_WIDTH - 4, CELL_HEIGHT - 4)
      else:
        drawUnknownCell(x, y)
    of 1..8:
      DRAW_COLORS[] = if (field[x][y] > 2): 0x4 else: 0x2
      text($field[x][y], x * CELL_WIDTH + 1, y * CELL_HEIGHT + 1)
    else:
      discard  

proc drawField =
  for x in 0..<WIDTH:
    for y in 0..<HEIGHT:
      drawCell(x,y)

proc printCenter(text: string, y: Coord) =
  text(text, (SCREEN_SIZE - text.len * FONT_SIZE) div 2, y)

proc drawStartScreen =
  DRAW_COLORS[] = 0x2
  printCenter("SAPPER", (SCREEN_SIZE - FONT_SIZE) div 2)
  printCenter("Press x to start", (SCREEN_SIZE + FONT_SIZE) div 2)
  printCenter("made by ov7a", SCREEN_SIZE - FONT_SIZE - FONT_SIZE div 2)

proc drawGameOver =
  DRAW_COLORS[] = 0x24
  printCenter("Game over", (SCREEN_SIZE - FONT_SIZE) div 2)
  printCenter("Press x", (SCREEN_SIZE + FONT_SIZE) div 2)

proc drawVictory =
  DRAW_COLORS[] = 0x24
  printCenter("Victory!", (SCREEN_SIZE - FONT_SIZE) div 2)
  printCenter("Press x", (SCREEN_SIZE + FONT_SIZE) div 2)

### Setup and update

proc setup =
  PALETTE[0] = 0xE0F8CF
  PALETTE[1] = 0x86C06C
  PALETTE[2] = 0x306850
  PALETTE[3] = 0xFF0000

# Call NimMain so that global Nim code in modules will be called, 
# preventing unexpected errors
proc NimMain {.importc.}

proc start {.exportWasm.} = 
  NimMain()
  # https://github.com/aduros/wasm4/issues/734
  #randomize()
  setup()

var previousGamepad: uint8
var frameCount: int

proc update {.exportWasm.} =
  frameCount += 1
  var gamepad = GAMEPAD1[]
  let keyPressed = gamepad and (gamepad xor previousGamepad)

  if bool(keyPressed and BUTTON_1):
    randomize(frameCount)
    restart()
  elif gameState == IN_PROGRESS and keyPressed != 0:
    mayBeMoveSapper(keyPressed)
  
  if gameState != START:
    drawField()
    drawSapper(sapperX, sapperY) 

  case gameState:
    of START:
      drawStartScreen()
    of OVER:
      drawGameOver()
    of VICTORY:
      drawVictory()  
    of IN_PROGRESS:
      discard  
  
  # must be at the end to avoid false updates
  previousGamepad = gamepad


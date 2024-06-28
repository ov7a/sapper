import cart/wasm4
import std/random

const WIDTH = 20
const HEIGHT = WIDTH
const CELL_WIDTH = SCREEN_SIZE div WIDTH
const CELL_HEIGHT = SCREEN_SIZE div HEIGHT

var sapperX: int 
var sapperY: int

proc drawSapper(x: int, y: int) = 
  DRAW_COLORS[] = 0x4
  oval(x * CELL_WIDTH + 2, y * CELL_HEIGHT + 2, CELL_WIDTH - 4, CELL_HEIGHT - 4)

proc drawCell(x: int, y: int) = 
  DRAW_COLORS[] = 0x23
  rect(x * CELL_WIDTH, y * CELL_HEIGHT, CELL_WIDTH, CELL_HEIGHT)

proc drawField =
  for x in 0..WIDTH:
    for y in 0..HEIGHT:
      drawCell(x,y)

proc setup =
  PALETTE[0] = 0xE0F8CF
  PALETTE[1] = 0x86C06C
  PALETTE[2] = 0x306850
  PALETTE[3] = 0xFF0000
  sapperX = rand(WIDTH)
  sapperY = rand(HEIGHT)

var previousGamepad: uint8

proc mayBeMoveSapper(keyPressed: uint8) =
  if bool(keyPressed and BUTTON_LEFT):
    sapperX = max(0, sapperX - 1)
  elif bool(keyPressed and BUTTON_RIGHT):
    sapperX = min(WIDTH - 1, sapperX + 1)
  elif bool(keyPressed and BUTTON_UP):
    sapperY = max(0, sapperY - 1)
  elif bool(keyPressed and BUTTON_DOWN):
    sapperY = min(HEIGHT - 1, sapperY + 1)

# Call NimMain so that global Nim code in modules will be called, 
# preventing unexpected errors
proc NimMain {.importc.}

proc start {.exportWasm.} = 
  NimMain()
  # https://github.com/aduros/wasm4/issues/734
  #randomize()
  setup()

proc update {.exportWasm.} =
  drawField()
  var gamepad = GAMEPAD1[]
  var keyPressed = gamepad and (gamepad xor previousGamepad)
  previousGamepad = gamepad

  mayBeMoveSapper(keyPressed)
  drawSapper(sapperX, sapperY) 

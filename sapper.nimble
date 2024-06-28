import std/[os, strformat]
# Package

version       = "0.1.0"
author        = "Vlad Chesnokov (ov7a)"
description   = "Sapper game"
license       = "MIT"
srcDir        = "src"

# Dependencies

let source = "src" / "sapper.nim"
let outFile = "build" / "sapper.wasm"
requires "nim >= 1.4.0"

task dbg, "Build the cartridge in debug mode":
  exec &"nim c -d:nimNoQuit -o:{outFile} {source}"

task rel, "Build the cartridge with all optimizations":
  exec &"nim c -d:nimNoQuit -d:danger --threads:off -o:{outFile} {source}"

task test, "experiment":
  exec &"nim c -d:nimNoQuit -d:danger --threads:off -o:build/test.wasm src/test.nim"

task play, "Run game":
  exec &"w4 run-native {outFile}"

after rel:
  let exe = findExe("wasm-opt")
  if exe != "":
    exec(&"wasm-opt -Oz --zero-filled-memory --strip-producers {outFile} -o {outFile}")
  else:
    echo "Tip: wasm-opt was not found. Install it from binaryen for smaller builds!"

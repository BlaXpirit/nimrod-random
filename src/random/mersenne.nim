# Copyright (C) 2014-2015 Oleh Prypin <blaxpirit@gmail.com>
# 
# This file is part of nim-random.
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.


import unsigned, math, times
import common, private/mt19937ar, urandom
export common


type MersenneTwister* = MTState
  ## Mersenne Twister (MT19937).
  ## Based on http://www.math.sci.hiroshima-u.ac.jp/~m-mat/MT/MT2002/emt19937ar.html

proc randomUint32*(self: var MersenneTwister): uint32 {.inline.} =
  self.genrandInt32()

proc random*(self: var MersenneTwister): float64 {.inline.} =
  self.genrandRes53()

proc initMersenneTwister*(): MersenneTwister =
  ## Initializes and returns a new ``MersenneTwister``
  initMTState()

proc seed*(self: var MersenneTwister; seed: uint32) {.inline.} =
  ## Seeds (randomizes) using 32 bits of an integer
  self.initGenrand(seed)

proc seed*(self: var MersenneTwister; seed: openarray[uint32]) {.inline.} =
  self.initByArray(seed)

proc seed*(self: var MersenneTwister; seed: openarray[uint8]) =
  ## Seeds (randomizes) using an array of bytes
  
  # Turn an array of uint8 into an array of uint32:
  
  var bytes = @seed
  let n = int(ceil(bytes.len/4)) # n bytes is ceil(n/4) 32bit numbers
  bytes.setLen(n*4) # add the missing bytes - should be zeros
  
  var words = newSeq[uint32](n)
  for i in 0..n-1:
    let i4 = i*4
    words[i] = uint32(bytes[i4]) or uint32(bytes[i4+1]) shl 8'u32 or
      uint32(bytes[i4+2]) shl 16'u32 or uint32(bytes[i4+3]) shl 24'u32
  
  self.initByArray(words)

proc seed*(self: var MersenneTwister) =
  ## Seeds (randomizes) using an array of bytes provided by ``urandom``, or,
  ## in case of failure, using the current time (with resolution of 1/256 sec)
  try:
    self.seed(urandom(2500))
  except OSError:
    self.seed(cast[uint32](epochTime()))


{.deprecated: [TMersenneTwister: MersenneTwister].}
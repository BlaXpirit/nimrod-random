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


import unsigned
import common, private/seeding
import private/xorshift128plus, private/xorshift1024star
import private/murmurhash3, private/xorshift64star
export common


type Xorshift128Plus* = Xorshift128PlusState
  ## xorshift128+
  ## based on http://xorshift.di.unimi.it/

proc randomUint64*(self: var Xorshift128Plus): uint64 {.inline.} =
  xorshift128plus.next(self)

proc checkSeed(self: var Xorshift128Plus) {.inline.} =
  if (self.s[0] or self.s[1]) == 0:
    raise newException(ValueError,
      "The state must be seeded so that it is not everywhere zero.")

proc initXorshift128Plus*(seed: array[2, uint64]): Xorshift128Plus =
  ## Seeds (randomizes) using 2 ``uint64``.
  ## The state must be seeded so that it is not everywhere zero.
  result.s = seed
  result.checkSeed()

makeBytesSeeding(Xorshift128Plus, uint64, "2")

proc initXorshift128Plus*(seed: uint64): Xorshift128Plus =
  ## Seeds (randomizes) using an ``uint64``.
  ## The state must be seeded so that it is not everywhere zero.
  # "If you have a 64-bit seed, we suggest to pass it twice
  # through MurmurHash3's avalanching function."
  let a = murmurhash3.next(seed)
  let b = murmurhash3.next(a)
  result.s = [a, b]
  result.checkSeed()


type Xorshift1024Star* = Xorshift1024StarState
  ## xorshift1024*
  ## based on http://xorshift.di.unimi.it/

proc randomUint64*(self: var Xorshift1024Star): uint64 {.inline.} =
  xorshift1024star.next(self)

proc checkSeed(self: var Xorshift1024Star) {.inline.} =
  var r: uint64
  for x in self.s:
    r = r or x
  if r == 0:
    raise newException(ValueError,
      "The state must be seeded so that it is not everywhere zero.")

proc initXorshift1024Star*(seed: array[16, uint64]): Xorshift1024Star =
  ## Seeds (randomizes) using 16 uint64.
  ## The state must be seeded so that it is not everywhere zero.
  result.s = seed
  result.p = 0
  result.checkSeed()

makeBytesSeeding(Xorshift1024Star, uint64, "16")

proc initXorshift1024Star*(seed: uint64): Xorshift1024Star =
  ## Seeds (randomizes) using an uint64.
  ## The state must be seeded so that it is not everywhere zero.
  # "If you have a 64-bit seed, we suggest to seed a
  # xorshift64* generator and use its output to fill s."
  var r: array[16, uint64]
  var rng = Xorshift64StarState(x: seed)
  for x in r.mitems:
    x = xorshift64star.next(rng)
  initXorshift1024Star(r)


when defined(test):
  import unittest
  
  suite "Xorshift128+":
    echo "Xorshift128+:"
    
    test "implementation":
      var rng = initXorshift128Plus([1234524356u64, 47845723665u64])
      check([rng.randomUint64(), rng.randomUint64(), rng.randomUint64()] == [
        10356027574996968u64, 421627830503766283u64, 7267806761253193977u64
      ])
      
      rng = initXorshift128Plus([262151541652562u64, 468594272265u64])
      check([rng.randomUint64(), rng.randomUint64(), rng.randomUint64()] == [
        3923822141990852456u64, 3993942717521754294u64, 13070632098572223408u64
      ])
  
  suite "Xorshift1024*":
    echo "Xorshift1024*:"

    test "implementation":
      var rng = initXorshift1024Star([4873361256124563431u64, 468594272265151u64,
        24562895618746132u64, 13135123616214u64, 446469974321u64,
        798436146749841u64, 64321987496463241u64, 0u64, 87942132u64,
        9879876514321846456u64, 654698741u64, 87984321u64, 546984321u64,
        4521584632u64, 6546459846165u64, 849416516516115u64
      ])
      check([rng.randomUint64(), rng.randomUint64(), rng.randomUint64()] == [
        17423166013011235612u64, 2597568971996913771u64, 780893741250465115u64
      ])
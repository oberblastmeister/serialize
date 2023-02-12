module Serialize
  ( Serialize (..),
    Get,
    Put,
    gConstSize,
    encode,
    encodeIO,
    decodeIO,
    decode',
    decode,
  )
where

import Serialize.Internal
import Serialize.Internal.Get
import Serialize.Internal.Put

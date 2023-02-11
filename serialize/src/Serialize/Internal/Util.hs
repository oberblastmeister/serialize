{-# LANGUAGE AllowAmbiguousTypes #-}

module Serialize.Internal.Util
  ( sizeOf##,
    unI#,
    unW#,
    (<!$!>),
    unpackByteString#,
    pinnedToByteString,
  )
where

import Data.ByteString (ByteString)
import Data.ByteString qualified as B
import Data.ByteString.Internal qualified as B.Internal
import Data.Primitive (Prim)
import Data.Primitive qualified as Primitive
import Foreign qualified
import GHC.ForeignPtr (ForeignPtr (..), ForeignPtrContents (PlainPtr))
import Serialize.Internal.Exts
import System.IO.Unsafe (unsafeDupablePerformIO)
import Unsafe.Coerce qualified

sizeOf## :: forall a. Prim a => Int#
sizeOf## = Primitive.sizeOf# (undefined :: a)
{-# INLINE sizeOf## #-}

unI# :: Int -> Int#
unI# (I# i#) = i#
{-# INLINE unI# #-}

unW# :: Word -> Word#
unW# (W# w#) = w#
{-# INLINE unW# #-}

(<!$!>) :: Monad m => (a -> b) -> m a -> m b
f <!$!> m = do
  !x <- m
  pure $! f x
{-# INLINE (<!$!>) #-}

unpackByteString# :: ByteString -> (# Primitive.ByteArray#, Int#, Int# #)
unpackByteString# bs@(B.Internal.PS (ForeignPtr (Primitive.Ptr -> p) fpc) o l) =
  (# arr#, off#, len# #)
  where
    !(Primitive.ByteArray arr#, I# off#, I# len#) = unsafeDupablePerformIO $ case fpc of
      PlainPtr (Primitive.MutableByteArray -> marr) -> do
        let base = Primitive.mutableByteArrayContents marr
            off = p `Foreign.minusPtr` base
        arr <- Primitive.unsafeFreezeByteArray marr
        pure (arr, off + o, off + o + l)
      _ -> case B.copy bs of
        B.Internal.PS (ForeignPtr (Primitive.Ptr -> p) fpc) o l -> case fpc of
          PlainPtr (Primitive.MutableByteArray -> marr) -> do
            let base = Primitive.mutableByteArrayContents marr
                off = p `Foreign.minusPtr` base
            arr <- Primitive.unsafeFreezeByteArray marr
            pure (arr, off + o, off + o + l)
          _ -> error "should be PlainPtr"

pinnedToByteString :: Primitive.ByteArray -> ByteString
pinnedToByteString bs@(Primitive.ByteArray b#)
  | Primitive.isByteArrayPinned bs = B.Internal.PS fp 0 len
  | otherwise = error "ByteArray must be pinned"
  where
    !(Primitive.Ptr addr#) = Primitive.byteArrayContents bs
    fp = ForeignPtr addr# (PlainPtr (Unsafe.Coerce.unsafeCoerce# b#))
    len = Primitive.sizeofByteArray bs

module Elves (
  pairs,
  getMatrix,
  minimalBinarySearch,
  maximalBinarySearch,
  minmax,
  locally,
  boundedSearch,
  applyN,
  applyNM,
  cyclePred,
  cycleSucc,
  best,
  bestTree,
  (<#>),
  module X
  ) where

import Control.Monad.State.Class
import Control.Applicative as X
import Data.List
import Data.Maybe
import Data.Monoid
import Data.Ord
import Data.Tree (Forest,Tree(..))
import Data.Bool
import Test.Hspec as X
import Data.Attoparsec.Text as X (Parser, parseOnly)

(<#>) :: Applicative f => f a -> f b -> f (a,b)
(<#>) = liftA2 (,)

pairs :: [a] -> [(a, a)]
pairs l = [(x,y) | (x:ys) <- tails l, y <- ys]

getMatrix :: (Read a) => IO [[a]]
getMatrix = fmap (fmap read . words) . lines <$> getContents

minmax :: Ord a => [a] -> Maybe (a,a)
minmax = foldl' (\mp x -> fmap (cmp x) mp <|> Just (x,x)) Nothing
  where cmp x (a,b) = (min x a, max x b)

-- call a function N times on a value
applyN :: Int -> (a -> a) -> a -> a
applyN n f = foldl' (.) id (replicate n f)

applyNM :: Monad m => Int -> (a -> m a) -> a -> m a
applyNM n act a = foldl' (>>=) (pure a) (replicate n act)

cyclePred :: (Enum a, Eq a, Bounded a) => a -> a
cyclePred x = if x == minBound then maxBound
                               else pred x

cycleSucc :: (Enum a, Eq a, Bounded a) => a -> a
cycleSucc x = if x == maxBound then minBound
                               else succ x

best :: Ord b => (a -> b) -> [a] -> Maybe a
best f = listToMaybe . sortBy (comparing (Down . f))

bestTree :: (Monoid b, Ord b) => (a -> b) -> Forest a -> b
bestTree f = maximum . (mempty :) . fmap ((<>) <$> f . rootLabel <*> bestTree f . subForest)

-- like local in Reader - this allows a stateful
-- action to run, and then have its modifications
-- discarded.
locally :: MonadState s m => m a -> m a
locally ma = do
  s <- get
  r <- ma
  put s
  return r

boundedSearch :: (Integral a, Num a, Enum a) => (a -> Bool) -> (a -> Bool) -> (a -> Bool) -> (a,a) -> Maybe a
boundedSearch lteq gteq eq bs = listToMaybe (filter eq [lb .. ub])
  where
    lb = maximalBinarySearch lteq bs
    ub = minimalBinarySearch gteq (lb, snd bs)

-- search downwards within the given range for our item, using bisection
minimalBinarySearch :: (Integral a, Num a) => (a -> Bool) -> (a,a) -> a
minimalBinarySearch isOK
  = binarySearch (subtract . bool 0 1 . even) $ \p rng ->
    if isOK p then (fst rng, p) else (p + 1, snd rng)

-- search upwards within the given range for our item, using bisection
maximalBinarySearch :: (Integral a, Num a) => (a -> Bool) -> (a,a) -> a
maximalBinarySearch isOK
  = binarySearch (pure id) $ \p rng ->
    if isOK p then (p, snd rng) else (fst rng, p - 1)

binarySearch :: (Integral a, Num a) => (a -> a -> a) -> (a -> (a,a) -> (a,a)) -> (a,a) -> a
binarySearch rangeAdjust nextRange = go
  where
    go rng | rngSize rng < 2 = fst rng
           | otherwise       = let p = mid rng in go (nextRange p rng)
    rngSize (a,b) = (b - a) + 1
    mid rng = let n = rngSize rng in fst rng + (rangeAdjust n $ div n 2)

module Elves.Advent where

import           Control.Applicative
import           Control.Monad
import           Data.Attoparsec.Text (Parser, endOfInput, parseOnly)
import qualified Data.Text.IO         as Text
import qualified Data.Time.Clock      as Clock
import           System.Environment
import           System.Exit
import           Text.Parser.Char     (newline)

import           Test.Hspec

type Part a = a -> IO ()

-- for exercises with simple input that can be inlined, and this is known statically
staticDay :: Int -> IO () -> IO () -> Spec -> IO ()
staticDay n pt1 pt2 spec = do
  args <- getArgs
  case args of
    ["pt1"]  -> pt1
    ["pt2"]  -> pt2
    ("test":test_args) -> withArgs test_args
                          $ hspec (describe ("Day " ++ show n) spec)
    _        -> die "bad arguments. Expected pt1,pt2 or test"

day :: Int -> Parser a -> Part a -> Part a -> Spec -> IO ()
day n parser pt1 pt2 spec = do
  staticDay n (getInput >>= pt1) (getInput >>= pt2) spec
  where
    getInput = Text.getContents >>= either (die . ("Could not parse input! " ++)) pure
                                    . parseOnly (parser <* (many newline >> endOfInput))

namedTime :: String -> IO () -> IO ()
namedTime name act = do
  when (not . null $ name) $ putStrLn name >> putStrLn (replicate (length name) '-')
  start <- Clock.getCurrentTime
  act
  end <- Clock.getCurrentTime
  print (Clock.diffUTCTime end start)
  when (not . null $ name) $ putStrLn (replicate (length name) '-')

time :: IO () -> IO ()
time = namedTime ""

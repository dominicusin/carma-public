{-# LANGUAGE OverloadedStrings, NoMonomorphismRestriction #-}
import Control.Monad.IO.Class
import Control.Monad
import Control.Monad.Trans
import Database.Redis
import qualified Data.ByteString.Char8 as B
import qualified Data.Map as M
import           Data.Map (Map)
import Data.Maybe
import Control.Applicative
import Data.Either
import Data.List

objKey :: B.ByteString -> B.ByteString -> B.ByteString
objKey model objId = B.concat [model, ":", objId]

modelIdKey :: B.ByteString -> B.ByteString
modelIdKey model = B.concat ["global:", model, ":id"]

main = do
  conn <- connect defaultConnectInfo
  runRedis conn $ do
    updPartnerOpts
    updCasePartner

updPartnerOpts = do
  Right ps <- keys "partner:*"
  -- 1272 - cases in old format
  let partners = filter (not . B.isPrefixOf "partner:name") ps
  forM_ partners $ \k -> do
    lp $ "migrating: " ++ show k
    Right partner <- g k
    let sids = B.split ',' $ fromMaybe "" $ M.lookup "services" partner
    ss <- grefs sids
    let cmpSrv a b = (M.lookup "serviceName" a) == (M.lookup "serviceName" b)
    -- group services by their name
    let groups = groupBy cmpSrv ss
    forM_ groups $ \sgrp -> do
      let optIds = foldl union [] $ map (mkids "tarifOptions") sgrp
      opts    <- grefs optIds
      newopts <- catMaybes <$> mapM (mkOption opts) sgrp
      let newids = map (fl "id") newopts
      -- add new options to redis
      mapM_ (\o -> hmset (fl "id" o) $ M.toList $ M.delete "id" o) newopts
      let optIds' = B.intercalate "," $ concat [optIds, newids]
      let curS  = head sgrp
      lp $ "setting to: " ++ show (fl "id" curS) ++
        " options: " ++ show optIds'
      hmset (fl "id" curS) [("tarifOptions",  optIds')]
    let (newSrvs, delSrvs) = foldl (\(a,b) (c,d) -> (a ++ c, b ++ d))
                               ([],[]) $ map (splitAt 1) groups
    lp $ "newSrvs: " ++ show (toIds newSrvs)
    lp $ "delSrvs: " ++ show (toIds delSrvs)
    hmset k [("services", toIds newSrvs)
            ,("delSrvs",  toIds delSrvs)
            ]

mkOption opts srv = do
  let srvId = fl "id" srv
      tname = lookupNE "tarifName" srv
      p1    = lookupNE "price1"    srv
      p2    = lookupNE "price2"    srv
  case all (== Nothing) [tname, p1,p2] of
    True -> return Nothing
    False -> do
      Right id <- incr $ modelIdKey "tarifOption"
      let idStr = B.pack $ show id
          tkey  = objKey "tarifOption" idStr
          o     = M.fromList [("id"        , tkey)
                             ,("parentId"  , srvId)
                             ,("optionName", fromMaybe "" tname)
                             ,("price1"    , fromMaybe "" p1   )
                             ,("price2"    , fromMaybe "" p2   )
                             ]
      -- check that we don't have this option already
      if (any (opteq o) opts)
        then return Nothing
        else return $ Just o

opteq a b = p1 a == p1 b && p2 a == p2 b && n a == n b
  where
    p1 = ml "price1"
    p2 = ml "price2"
    n  = ml "optionName"
toIds l = B.intercalate "," $ map (fl "id") l
fl f = fromJust . M.lookup f
ml f m = fromMaybe "" $ M.lookup f m
mkids f m = filter (/= "") $ B.split ',' $ ml f m
g      id = (M.fromList <$>) <$> hgetall id
grefs ids = rights <$> mapM hgetall' ids
hgetall' id = do
  a <- hgetall id
  case a of
    Left r  -> return $ Left r
    Right r -> return $ Right $ M.insert "id" id $ M.fromList r

-- grefs ids = rights <$> mapM hgetall ids
  
-- updPartnerOpts = do
--   Right ps <- keys "partner:*"
--   forM_ (filter (not . B.isPrefixOf "partner:name") ps) $ \k -> do
--     Right p <- hgetall k
--     let p' = M.fromList p
--     case M.lookup "services" $ M.fromList p of
--       Nothing -> return ()
--       Just ss
--         | B.length ss < 23 && B.length ss > 15 ->
--           forM_ (B.split ',' ss) $ \srvId -> do
--             srv <- hgetall srvId
--             hmset srvId [("priority1",
--                           fromMaybe "" $ lookupNE "priority1" p')
--                         ,("priority2",
--                           fromMaybe "" $ lookupNE "priority2" p')
--                         ,("priority3",
--                           fromMaybe "" $ lookupNE "priority3" p')
--                         ]
--             liftIO $ print $ "move priorities from: " ++ show k ++ " to " ++ show srvId
--             case srv of
--               Left _  -> return ()
--               Right s -> do
--                 let tname = lookupNE "tarifName" p'
--                     p1    = lookupNE "price1"    p'
--                     p2    = lookupNE "price2"    p'
--                 case all (== Nothing) [tname, p1,p2] of
--                   True  -> do
--                     liftIO $ print $ "nothing to make tarifOption for: " ++ show srvId
--                     return ()
--                   False -> do
--                     Right id <- incr $ modelIdKey "tarifOption"
--                     let idStr = B.pack $ show id
--                         tkey  = objKey "tarifOption" idStr
--                     liftIO $ print $ "going to set " ++ show tkey
--                     hmset tkey [("id"        , idStr)
--                                ,("parentId"  , srvId)
--                                ,("optionName", fromMaybe "" tname)
--                                ,("price1"    , fromMaybe "" p1   )
--                                ,("price2"    , fromMaybe "" p2   )
--                                ]
--                     liftIO $ print $ "created tarifOption: " ++ show tkey
--                     hmset srvId [("tarifOptions", tkey)]
--                     liftIO $ print $ "set " ++ show srvId ++ " tarifOptions: " ++ show tkey
--                     return ()
--         | otherwise -> return ()

updCasePartner = do
  Right ps <- keys "partner:*"
  plst <- forM (filter (not . B.isPrefixOf "partner:name") ps) $ \k -> do
    Right p <- hgetall k
    return (fromMaybe "" $ M.lookup "name" $ M.fromList p, M.fromList p)
  -- make map partner -> partnerid
  let pmap = M.fromList plst
  Right casesIds <- keys "case:*"
  cases <- map M.fromList <$> rights <$> mapM hgetall casesIds
  -- thru cases
  forM_ cases $ \k -> do
    let ss = B.split ',' $ fromMaybe "" $ M.lookup "services" k
    -- liftIO $ print $ "updating case: " ++ show k
    -- thru services
    forM_ ss $ \sId -> do
      liftIO $ print $ "updating service: " ++ show sId
      Right srv <- hgetall sId
      let srvm = M.fromList srv
      case flip M.lookup pmap =<< M.lookup "contractor_partner" srvm of
        Nothing  -> return ()
        Just p   -> do
          -- liftIO $ print "got just cp"
          let partnerId = return . objKey "partner" =<<  M.lookup "id" p
          case partnerId of
            Nothing        ->
              liftIO $ print $ "can't find id for " ++
                (show $ fromJust $ M.lookup "contractor_partner" srvm)
            Just partnerId -> do
              hmset sId [( "contractor_partnerId", partnerId )]
              return ()

          liftIO $ print $ "setting " ++ show sId ++ " contractor_partnerId " ++ show partnerId
          case return . B.split ',' =<< M.lookup "services" p of
            Nothing -> return ()
            Just ps -> do
              let srvName = head $ B.split ':' sId
              pservices <- map M.fromList <$> rights <$> mapM hgetall ps
              let samesrv = find (\s -> (fromMaybe "" $ M.lookup "serviceName" s) == srvName) pservices
              case samesrv of
                Nothing -> return ()
                Just v  -> do
                  let perc = fromMaybe "" $ M.lookup "falseCallPercent" v
                  hmset sId [("falseCallPercent", perc)]
                  liftIO $ print $ "set " ++ show sId ++ " falseCallPercent " ++ show perc
                  return ()


-- | Like Map.lookup but treat Just "" as Nothing
lookupNE :: Ord k => k -> Map k B.ByteString -> Maybe B.ByteString
lookupNE key obj = M.lookup key obj >>= lp
  where lp "" = Nothing
        lp v  = return v

lp = liftIO . print
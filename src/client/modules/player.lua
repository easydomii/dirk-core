Core.Player = {
  CurJob = {},

  Ready = function()
    local start_time = GetGameTimer()
    if Config.Framework == "es_extended" then
      
      while not ESX do Wait(5000); end
      while not ESX.IsPlayerLoaded() do 
        print('Hung at PLAYER LOADED') 
        local now = GetGameTimer()
        if now - start_time >= Config.WaitForPlayerReady * 1000 then print('SKIPPED WAITING FOR PLAYER LOADED AS TOOK TOO LONG') return true; end
        Wait(500) 
      end
    elseif Config.Framework == "qb-core" then
      while not QBCore do print('AWAITING QBCORE OBJECT') Wait(500); end
      while not QBCore.Functions.GetPlayerData().job do   
        local now = GetGameTimer()
        if now - start_time >= Config.WaitForPlayerReady * 1000 then print('SKIPPED WAITING FOR PLAYER LOADED AS TOOK TOO LONG') return true; end 
        Wait(500)
      end
    end
    return true
  end,

  HasItem = function(item,amount, md) 
    local ret = nil 
    Core.Callback("Dirk-Core:HasItem", function(hasItem)
      ret = hasItem
    end, item, amount, md)
    while ret == nil do Wait(0); end
    return ret
  end,

  Job = function()
    return Core.Player.CurJob
  end,

  Identifier = function()
    if Config.Framework == "es_extended" then
      local data = ESX.GetPlayerData()
      return data.identifier
    elseif Config.Framework == "qb-core" then
      local data = QBCore.Functions.GetPlayerData()
      return data.citizenid
    end
  end,

  Gang = function()

    -- local formatted = {

    -- }
    -- if Config.GangSystem == "t1ger_gangsystem" then 
    --   return formatted
    -- elseif Config.GangSystem == "rcore_gangs" then
    --   local gang = exports['rcore_gangs']:GetPlayerGang()
    --   return formatted
    -- else
      if Config.Framework == "es_extended" then return "None"; end
      local data = QBCore.Functions.GetPlayerData()
      return data.gang.name
    -- end
  end,

  -- GangRep = function(value)
  --   if Config.GangSystem == "t1ger_gangsystem" then 
  --     local myGang = exports['t1ger_gangsystem']:GetPlayerGang(ply)
  --     if not myGang then return; end 

  --     exports['t1ger_gangsystem']:MinusGangNotoriety(myGang, 15) --## This is where you'd change how much it gives you for a successful sale
  --   elseif Config.RCORE_GANGS then 
  
  --   elseif Config.TEBIT_TERRITORIES then 
  
  --   end
  -- end,

  IsCop = function()
    for k,v in pairs(Config.PoliceJobs) do
      if Core.Player.CurJob.name == k then
        return true
      end
    end
    return false
  end,

  GetGang = function()
    local gt = {}

    if Config.Framework == "qb-core" then 
      if not Config.GangSystem then 
        local rawGang = QBCore.Functions.GetPlayerData().gang
        gt.name  = rawGang.name
        gt.label = rawGang.label
        gt.rank  = rawGang.grade.level
        gt.rankL = rawGang.grade.name
      end
    end
    return gt
  end,

  GetJob = function()
    local jt = {}
    if Config.Framework == "es_extended" then
      local data = ESX.GetPlayerData()
      jt.name  =  data.job.name
      jt.label =  data.job.label
      jt.rank  =  data.job.grade
      jt.rankL =  data.job.grade_label
      jt.duty   = true
      jt.isBoss = false
      jt.isCop =  Config.PoliceJobs[data.job.name]
    elseif Config.Framework == "qb-core" then
      local data = QBCore.Functions.GetPlayerData()
      while not data.job do data = QBCore.Functions.GetPlayerData() Wait(500); end 
      jt.name   = data.job.name
      jt.label  = data.job.label
      jt.rank   = data.job.grade.level
      jt.duty   = data.job.onduty
      jt.isBoss = data.job.isboss
      jt.isCop  = Config.PoliceJobs[data.job.name]
    end
    Core.Player.CurJob = jt
    return Core.Player.CurJob
  end,

  PlayAnim = function(data)
    while not HasAnimDictLoaded(data.dict) do RequestAnimDict(data.dict) Wait(0); end
    TaskPlayAnim(data.ent, data.dict, data.anim, 8.0, 8.0, -1, -1, -1, false, false, false)
    FreezeEntityPosition(data.ent, data.freeze)
    SetTimeout(data.time, function()
      ClearPedTasks(data.ent)
      if data.freeze then FreezeEntityPosition(data.ent, false); end
    end)
  end,
}

CreateThread(function()
  while not Config.Framework do Wait(500); end
  if Config.Framework == "es_extended" then
    RegisterNetEvent("esx:setJob", function(job)
      TriggerEvent("Dirk-Core:JobChange", Core.Player.GetJob())
    end)
  elseif Config.Framework == "qb-core" then
    if not Config.GangSystem then 
      RegisterNetEvent('QBCore:Client:OnGangUpdate', function(InfoGang)
        TriggerEvent("Dirk-Core:GangChange", Core.Player.GetGang())
      end)
    end

    RegisterNetEvent('QBCore:Client:OnJobUpdate', function(job)
      TriggerEvent("Dirk-Core:JobChange", Core.Player.GetJob())
    end)
  end
end)


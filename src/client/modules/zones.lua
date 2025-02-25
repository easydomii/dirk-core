local glm = require 'glm'
local polygons = {}
Core.Zones = {
  Register = function(id, data)
    local self = {}
    self.InvokingResource = GetInvokingResource()
    self.ID      = id
    self.Type    = data.Type or "circle"
    self.Radius  = data.Radius or 5.0
    self.Zone    = data.Zone
    if self.Type == "poly" then
      polygons[self.ID] = glm.polygon.new(self.Zone)
    end
    self.onLeave = data.onLeave or nil
    self.onEnter = data.onEnter or nil
    self.onStay  = data.onStay  or nil
    self.Draw    = data.Draw or {
      Enabled = false,
      Col     = {R = 255, G = 0, B = 0, A = 50} 
    }

    Core.Zones[self.ID] = self
  end,

  RemoveZone = function(id)
    Core.Zones[id] = nil
  end,

  ToggleDraw = function(id, bool)
    Core.Zones[id].Draw.Enabled = bool
  end,

  EditColors = function(id, col)
    Core.Zones[id].Draw.Col = col
  end,

  --## CIRCLE FUNCTIONS


  --## POLYGON FUNCTIONS
  IsPointInside = function(point, polygon)
    for k,v in pairs(polygon) do 
      polygon[k] = vector3(v.x,v.y, point.z) 
    end
    local polygon = glm.polygon.new(polygon)
    return polygon:contains(point)
  end,

  getMinMax = function(points)
    local minX, maxX = nil,nil
    local minY, maxY = nil,nil
    local minZ, maxZ = nil,nil

    for k,v in ipairs(points) do
      if not minX or v.x < minX then minX = v.x; end
      if not minY or v.y < minY then minY = v.y; end
      if not minZ or v.z < minZ then minZ = v.z; end

      if not maxX or v.x > maxX then maxX = v.x; end
      if not maxY or v.y > maxY then maxY = v.y; end
      if not maxZ or v.z > maxZ then maxZ = v.z; end
    end

    return minX, maxX, minY, maxY, minZ, maxZ
  end,

  DrawWall = function(pos1,pos2,height, col)
    col = col or {}
    local r,g,b,a = col.R or 0, col.G or 255, col.B or 0 , col.A or 0.5
    local topLeft     = vector3(pos1.x, pos1.y, pos1.z + height)
    local bottomLeft  = vector3(pos1.x,pos1.y,pos1.z)
    local topRight    = vector3(pos2.x,pos2.y,pos2.z + height)
    local bottomRight = vector3(pos2.x,pos2.y,pos2.z)
    DrawPoly(bottomLeft,topLeft,bottomRight,r,g,b,a)
    DrawPoly(topLeft,topRight,bottomRight,r,g,b,a)
    DrawPoly(bottomRight,topRight,topLeft,r,g,b,a)
    DrawPoly(bottomRight,topLeft,bottomLeft,r,g,b,a)
  end,

  CreatePolygon = function()
    local polygon = {}
    local height  = 5.0
    while true do 
      local wait_time = 0
      local ply = PlayerPedId() 
      for k,v in pairs(polygon) do 
        local firstPoint, secondPoint
        if k == 1 then 
          firstPoint = polygon[#polygon]
          secondPoint = polygon[k]
        else
          firstPoint = polygon[k - 1]
          secondPoint = polygon[k]
        end

        Core.Zones.DrawWall(firstPoint, secondPoint, height)
        DrawLine(firstPoint.x, firstPoint.y, i, secondPoint.x, secondPoint.y, i, 255, 0, 0, 255)
      end

      local hit, testCoords, entityHit = Core.UI.ScreenToWorld()
      if (testCoords ~= vector3(0,0,0) and entityHit ~= ply) then
        endCoords = testCoords 
        DrawSphere(endCoords.x,endCoords.y,endCoords.z, 0.2, 255,0,0, 0.7)
      end

     
      Core.UI.AdvancedHelpNotif("polygonPlotter", {
        {
          label = "Add Point",
          key   = "g"
        },
        {
          label = "Remove Last Point",
          key   = "h"
        },
        {
          label = "Finish Polygon",
          key   = "x"
        },
        {
          label = "Increase Height", 
          key   = "⬆️"
        },
        {
          label = "Decrease Height", 
          key   = "⬇️"
        },
        {
          label = "Cancel Polygon",
          key   = "q"
        }
      })
      DisableControlAction(0,47)
      DisableControlAction(0,74)
      DisableControlAction(0,105)
      DisableControlAction(0,172)
      DisableControlAction(0,173)
      DisableControlAction(0,85)

      if IsDisabledControlJustPressed(0, 47) then 
        polygon[#polygon + 1] = endCoords
      elseif IsDisabledControlJustPressed(0, 74) then
        polygon[#polygon] = nil
      elseif IsDisabledControlJustPressed(0, 105) then
        return polygon, height
      elseif IsDisabledControlPressed(0, 172) then
        height = height + 0.05
      elseif IsDisabledControlPressed(0, 173) then
        height = height - 0.05
      elseif IsDisabledControlJustPressed(0, 85) then
        return false
      end


      Wait(wait_time)
    end
  end, 

  CreateCirlce = function()
    local type = "3d"
    local pos  = GetEntityCoords(PlayerPedId())
    local radius = 5.0
    while true do 



      Wait(0)
    end
  end,


  plotPolygon = function(points, pointDist, minDistance)
    local xMin,xMax,yMin,yMax,zMin,zMax = Core.Zones.getMinMax(points)
    local polygon = glm.polygon.new(points)

    local z = zMin + (zMax - zMin)
    local height = (zMax - zMin) * 2
    local step = pointDist or 1

    local plot = {}

    for x=xMin,xMax,step do
      for y=yMin,yMax,step do
        local point = vector3(x, y, z)

        if polygon:contains(point, height) then
          table.insert(plot, point)
        end
      end
    end

    if minDistance then
      for j=1,#plot,1 do
        if plot[j] then
          for i=#plot,1,-1 do
            if j ~= i then
              local dist = #(plot[i] - plot[j])

              if dist < minDistance then
                table.remove(plot, i)

              end
            end
          end
        end
      end
    end

    return plot
  end,
}

RegisterCommand("Dirk-Core:DrawPolygon", function(source,arg)
  local polygon = Core.Zones.CreatePolygon()
  Core.UI.Notify("Copied Polygon to Clipboard")
  print(Core.UI.CopyToClipboard(json.encode(polygon)))
end)

local garbageCollection = GetGameTimer()

CreateThread(function()
  local valType = type
  while not Config.Framework do Wait(500); end
  local drawWall = Core.Zones.DrawWall
  while true do 
    local ply = PlayerPedId()
    local myCoords = GetEntityCoords(ply)
    local wait_time = 1000
    local now = GetGameTimer()
    if now - garbageCollection >= 60000 then 
      collectgarbage("collect")
      garbageCollection = now
    end
  
    for k,v in pairs(Core.Zones) do 
      if valType(v) ~= "function" then 
        if v.Type == "poly" then 
          if v.Zone then 
            if Config.DrawDebug or v.Draw.Enabled then 
              wait_time = 0 
              for index,data in pairs(v.Zone) do 
                if #(myCoords.xy - data.xy) <= 250.0 then  
                  local firstPoint, secondPoint
                  if index == 1 then 
                    firstPoint = v.Zone[#v.Zone]
                    secondPoint = v.Zone[index]
                  else
                    firstPoint = v.Zone[index - 1]
                    secondPoint = v.Zone[index]
                  end
                  
                  drawWall(firstPoint, secondPoint, 25.0, {R = v.Draw.Col.R, G = v.Draw.Col.G, B = v.Draw.Col.B, A = v.Draw.Col.A})
                  DrawLine(firstPoint.x, firstPoint.y, i, secondPoint.x, secondPoint.y, i, v.Draw.Col.R, v.Draw.Col.G, v.Draw.Col.B, v.Draw.Col.A)
                end
              end
            end
            if polygons[v.ID]:contains(myCoords, 2.0) then 
              if not v.Inside then 
                Core.Zones[k].Inside = true
                if v.onEnter then 
                  v.onEnter()
                end
              else 
                if v.onStay then 
                  v.onStay()
                  if v.onStayLoopTime and v.onStayLoopTime <= wait_time then 
                    wait_time = v.onStayLoopTime
                  end
                end
              end
            elseif Core.Zones[k].Inside then
              Core.Zones[k].Inside = false
              if v.onLeave then 
                v.onLeave()
              end
            end
          end
        elseif v.Type == "circle" then 

          if #(myCoords.xy - v.Zone.xy) <= (v.Radius or 5.0) then 
            local circleType = (v.Zone.z) and "3d" or "2d"
            if Config.DrawDebug or v.Draw.Enabled then 
              wait_time = 0 
              if circleType == "3d" then 
                DrawSphere(v.Zone.x, v.Zone.y, v.Zone.z, v.Radius or 5.0, v.Draw.Col.R or 255, v.Draw.Col.G or 0, v.Draw.Col.B or 0, (v.Draw.Col.A/255) or 0.6)
              elseif circleType == "2d" then 
                DrawMarker(1, v.Zone.x, v.Zone.y, 0.0, 0, 0, 0, 0, 0, 0, v.Radius or 5.0, v.Radius or 5.0, 9999.9999, v.Draw.Col.R or 255, v.Draw.Col.G or 0, v.Draw.Col.B or 0, v.Draw.Col.A or 0.5, false, false, 2, false, false, false, false)
              end
            end
            if (circleType == "3d" and myCoords.z - v.Zone.z <= (v.Radius or 5.0)) or circleType == "2d"  then 
              if not v.Inside then 
                Core.Zones[k].Inside = true
                if v.onEnter then 
                  v.onEnter()
                end
              else 
                if v.onStay then 
                  v.onStay()
                  if v.onStayLoopTime and v.onStayLoopTime <= wait_time then 
                    wait_time = v.onStayLoopTime
                  end
                end
              end
            else
              if Core.Zones[k].Inside then
                Core.Zones[k].Inside = false
                if v.onLeave then 
                  v.onLeave()
                end
              end
            end
          else
            if Core.Zones[k].Inside then
              Core.Zones[k].Inside = false
              if v.onLeave then 
                v.onLeave()
              end
            end
          end

        elseif v.Type == "box" then 
        elseif v.Type == "entity" then

      

        elseif v.Type == "look" then 
          if valType(v.Zone) == "vector3" then 
            local dist = #(myCoords - v.Zone.xyz)
            print(' Likely Vector3')
          elseif valType(v.Zone) == "number" then 
            print(' Likely ENtity') 
          elseif valType(v.Zone) == "table" then 
            print(' Table of entities')
          end

        end
      end

    end
    Wait(wait_time)
  end
end)


AddEventHandler("onResourceStop", function(resource)
  local count = 0
  for k,v in pairs(Core.Zones) do 
    if type(v) ~= "function" then 
      if v.InvokingResource == resource or resource == "dirk-core" then 
        count = count + 1
        Core.Zones[k] = nil
      end
    end
  end
  if count > 0 then 
    print("^2Dirk-Core^7 | Cleaned up ^5"..count.."^7 zones for resource: ^3"..resource.."^7")
  end
end)
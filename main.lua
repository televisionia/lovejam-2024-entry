-- Data table for things like maps and images
DATA = {}

-- Manages objects and map
GAME = {}

-- Client data
PLAYER = {}

-- Root directory
ROOT_DIR = ""

-- Push
local push
local gameWidth, gameHeight = 640, 360
local windowWidth, windowHeight = love.window.getDesktopDimensions()
windowWidth, windowHeight = windowWidth*.7, windowHeight*.7

-- Camera library
local camera

-- Camera object for the game world
local world_cam

-- Camera object for the game hud
local hud_cam

-- Simple Tiled Implementation 
local sti

local function split_string (inputstr, sep)
    if sep == nil then
            sep = "%s"
    end
    local t={}
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
            table.insert(t, str)
    end
    return t
end

function love.load()
    camera = require 'libraries.camera'
    world_cam = camera()
    hud_cam = camera()

    sti = require 'libraries.sti'
    push = require 'libraries.push'

    love.graphics.setDefaultFilter("nearest")

    push:setupScreen(gameWidth, gameHeight, windowWidth, windowHeight, {fullscreen = false, pixelperfect = true})

    PLAYER = {
        speed = 300,
        x = 0,
        y = 0
    }

    DATA = {}

    DATA.images = {}
    for _,file in pairs(love.filesystem.getDirectoryItems(ROOT_DIR.."sprites/")) do
        DATA.images[file] = {}
        for _,image in pairs(love.filesystem.getDirectoryItems(ROOT_DIR.."sprites/"..file.."/")) do
            DATA.images[file][image] = love.graphics.newImage(ROOT_DIR.."sprites/"..file.."/"..image.."/")
        end
    end

    DATA.fonts = {}
    for _,fontfile in pairs(love.filesystem.getDirectoryItems(ROOT_DIR.."/fonts/")) do
        DATA.fonts[fontfile:match("(.+)%..+$")] = love.graphics.newFont(ROOT_DIR.."/fonts/"..fontfile)
    end

    DATA.maps = {}
    for _,map in pairs(love.filesystem.getDirectoryItems(ROOT_DIR.."maps/mapfiles/")) do
        DATA.maps[map] = sti(ROOT_DIR.."maps/mapfiles/"..map)
    end

    DATA.event = {}
    for _,eventfile in pairs(love.filesystem.getDirectoryItems(ROOT_DIR.."data/event/")) do
        DATA.event[eventfile:match("(.+)%..+$")] = require(ROOT_DIR.."data.event."..eventfile:match("(.+)%..+$"))
    end

    DATA.layout = {}
    for _,layoutfile in pairs(love.filesystem.getDirectoryItems(ROOT_DIR.."data/layout/")) do
        DATA.layout[layoutfile:match("(.+)%..+$")] = require(ROOT_DIR.."data.layout."..layoutfile:match("(.+)%..+$"))
    end



    GAME = {
        world = {
            dynamic = {},
            static = {},
            visual = {}
        },
        hud = {},
        map = {
            layers = {}
        }
    }

    GAME.object = {
        default_properties = {
            type = "sprite",
            x = 0,
            y = 0,
            r = 0,
            texture = DATA.images.error["error.png"],
            sx = 1,
            sy = 1,
            font_size = 10,
            align_text = "left",
            click_width = "32",
            click_height = "32"
        }
    }

    function GAME.object:new(objectname, location, properties)
        location[objectname] = {}
        for property,value in pairs(GAME.object.default_properties) do
            location[objectname][property] = value
        end

        if properties then
            for property,value in pairs(properties) do
                location[objectname][property] = value
            end
        end
    end

    function GAME.object:remove(object)
        object = nil
    end

    function GAME.object:copy_objects(objects, location)
        for object_name,object_properties in pairs(objects) do
            GAME.object:new(object_name, location, object_properties)
        end
    end

    function GAME.object:check_for_object_at(x, y, location)
        if x ~= nil and y ~= nil then
            for _,object in pairs(location) do
                print(object.click_width)
                print(object.click_height)
                if object.x <= x and object.x + object.click_width >= object.x and object.y <= y and object.y + object.click_height >= y then
                    return object
                end
            end
        end
        return nil
    end

    function GAME.object:activate_object(object)
        if object.event ~= nil then
            local event_path = split_string(object.event, ".")
            event_path[2] = event_path[2]:gsub('%(', '')
            event_path[2] = event_path[2]:gsub('%)', '')

            DATA.event[event_path[1]][event_path[2]]()
        end
    end

    DATA.event.general:init_game()
end

function love.update(dt)
    if love.keyboard.isDown('left') then
        PLAYER.x = PLAYER.x - PLAYER.speed * dt
    elseif love.keyboard.isDown('right') then
        PLAYER.x = PLAYER.x + PLAYER.speed * dt
    end

    if love.keyboard.isDown('up') then
        PLAYER.y = PLAYER.y - PLAYER.speed * dt
    elseif love.keyboard.isDown('down') then
        PLAYER.y = PLAYER.y + PLAYER.speed * dt
    end

    world_cam:lookAt(PLAYER.x, PLAYER.y)
end

function love.mousepressed(x, y, button)
    if button == 1 then
        local mousepos_x, mousepos_y = push:toGame(x, y)
        local find_object = GAME.object:check_for_object_at(mousepos_x, mousepos_y, GAME.hud)
        if find_object ~= nil then
            GAME.object:activate_object(find_object)
        end
    end
  end

function love.draw()

    push:start()

    world_cam:attach()

    -- WORLD --

    for _,layer in pairs(GAME.map.layers) do
       GAME.map:drawLayer(layer)
    end

    for category_name,current_category in pairs(GAME.world) do
        for _,current_object in pairs(current_category) do
            if current_object.texture ~= "" then
                love.graphics.draw(current_object.texture, current_object.x, current_object.y, current_object.r, current_object.sx, current_object.sy)
            end
        end
    end
    
    world_cam:detach()

    -----------

    -- HUD --

    --hud_cam:attach()

    for _,current_object in pairs(GAME.hud) do
        if current_object.texture ~= "" then
            love.graphics.draw(current_object.texture, current_object.x, current_object.y, current_object.r, current_object.sx, current_object.sy)
        end
        if current_object.text then
            love.graphics.printf(current_object.text, current_object.x + current_object.text_offset_x, current_object.y + current_object.text_offset_y, current_object.text_width, current_object.align_text)
        end
    end

    --hud_cam:detach()

    ---------

    push:finish()

end
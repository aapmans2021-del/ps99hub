--[[
   PET SIMULATOR 99 HUB
   Same look as the Pet Dimensions hub: Sakura Dusk window over the animated
   mountain scene, numbered sidebar tabs with a sliding glider, section cards,
   spring switches, a command palette (` key), toasts and saved settings.

   Everything here was checked live against the game. Nothing travels to
   another world; features that need to stand somewhere (timed reward
   machines, balloon gifts) hop there inside the current world and return.
]]

repeat task.wait() until game:IsLoaded()

local env = getgenv and getgenv() or _G
if env.__PS99HUB_CLEANUP then pcall(env.__PS99HUB_CLEANUP) end
if env.__PS99_AH_CLEANUP then pcall(env.__PS99_AH_CLEANUP) end

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local CollectionService = game:GetService("CollectionService")
local LocalPlayer = Players.LocalPlayer
repeat task.wait() until not LocalPlayer.PlayerGui:FindFirstChild("__INTRO")

-- =====================================================================
-- STARTUP SCENE: SAKURA DUSK
-- Shared by the key gate and the loading screen so the hand-off reads as
-- one shot. A dusk sky with drifting sunset cloud, a haloed moon, four
-- depths of mountains with mist between them (a far ridge, Mount Fuji with
-- a snow cap and gullies, a jagged mid range, tree-lined near hills), a
-- still lake that mirrors Fuji and a torii standing in the water, lanterns
-- drifting up, and branching sakura trees with weeping blossom strands
-- framing the view while petals fall. UI has no triangles, so every
-- mountain is drawn as a run of thin vertical slices.
-- pdBuildScene(parent) -> { frame, setSpeed(n), stop() }
-- =====================================================================
local function pdBuildScene(parent, opts)
    opts = type(opts) == "table" and opts or {}
    local RunService = game:GetService("RunService")
    local HORIZON = 0.68
    local rng = Random.new(21)
    local PINKS = {
        Color3.fromRGB(255, 183, 206), Color3.fromRGB(248, 150, 186), Color3.fromRGB(255, 212, 226),
        Color3.fromRGB(240, 136, 176), Color3.fromRGB(255, 198, 216),
    }
    local BLOSSOM_SHADOW = Color3.fromRGB(196, 96, 146)
    local BLOSSOM_LIGHT = Color3.fromRGB(255, 232, 240)

    local scene = Instance.new("Frame")
    scene.Name = "Scene"
    scene.Size = UDim2.fromScale(1, 1)
    scene.BackgroundColor3 = Color3.new(1, 1, 1)
    scene.BorderSizePixel = 0
    scene.ClipsDescendants = true
    scene.Parent = parent
    do
        local sky = Instance.new("UIGradient")
        sky.Rotation = 90
        sky.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(16, 12, 40)),
            ColorSequenceKeypoint.new(0.3, Color3.fromRGB(52, 28, 80)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(132, 62, 116)),
            ColorSequenceKeypoint.new(HORIZON - 0.03, Color3.fromRGB(236, 140, 140)),
            ColorSequenceKeypoint.new(HORIZON - 0.005, Color3.fromRGB(255, 186, 150)),
            ColorSequenceKeypoint.new(HORIZON + 0.005, Color3.fromRGB(58, 34, 72)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(14, 10, 24)),
        })
        sky.Parent = scene
    end

    local function frame(colour, transparency, parent2)
        local f = Instance.new("Frame")
        f.BackgroundColor3 = colour
        f.BackgroundTransparency = transparency or 0
        f.BorderSizePixel = 0
        f.Parent = parent2 or scene
        return f
    end
    local function round(f, r)
        local c = Instance.new("UICorner") c.CornerRadius = r or UDim.new(1, 0) c.Parent = f
        return f
    end
    local function band(y, height, colour, peak)
        local f = frame(colour, 0)
        f.AnchorPoint = Vector2.new(0, 0.5)
        f.Position = UDim2.fromScale(0, y)
        f.Size = UDim2.fromScale(1, height)
        local g = Instance.new("UIGradient")
        g.Rotation = 90
        g.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, peak), NumberSequenceKeypoint.new(1, 1),
        })
        g.Parent = f
        return f, g
    end
    local function softDisc(x, y, size, colour, layers, alpha, parent2)
        local holder = frame(colour, 1, parent2)
        holder.AnchorPoint = Vector2.new(0.5, 0.5)
        holder.Position = UDim2.fromScale(x, y)
        holder.Size = UDim2.fromScale(size, size)
        holder.SizeConstraint = Enum.SizeConstraint.RelativeYY
        for layer = 1, layers do
            local d = round(frame(colour, alpha, holder))
            d.AnchorPoint = Vector2.new(0.5, 0.5)
            d.Position = UDim2.fromScale(0.5, 0.5)
            d.Size = UDim2.fromScale(layer / layers, layer / layers)
        end
        return holder
    end

    -- stars
    local stars = {}
    for i = 1, 60 do
        local s = round(frame(Color3.fromRGB(255, 236, 246), 0.5))
        s.AnchorPoint = Vector2.new(0.5, 0.5)
        local size = rng:NextNumber() < 0.2 and 3 or 2
        s.Size = UDim2.fromOffset(size, size)
        s.Position = UDim2.fromScale(rng:NextNumber(), rng:NextNumber() ^ 1.4 * 0.42)
        stars[i] = { frame = s, phase = rng:NextNumber() * 6.28, speed = rng:NextNumber(0.5, 1.8) }
    end

    -- moon and halo
    local MOON_X, MOON_Y = 0.74, 0.22
    local halo = softDisc(MOON_X, MOON_Y, 0.5, Color3.fromRGB(255, 205, 222), 20, 0.987)
    local moon = round(frame(Color3.new(1, 1, 1), 0))
    moon.AnchorPoint = Vector2.new(0.5, 0.5)
    moon.SizeConstraint = Enum.SizeConstraint.RelativeYY
    moon.Position = UDim2.fromScale(MOON_X, MOON_Y)
    moon.Size = UDim2.fromScale(0.16, 0.16)
    do
        local g = Instance.new("UIGradient")
        g.Rotation = 125
        g.Color = ColorSequence.new(Color3.fromRGB(255, 251, 246), Color3.fromRGB(255, 214, 224))
        g.Parent = moon
        -- faint maria
        for _, m in ipairs({ { 0.35, 0.4, 0.22 }, { 0.6, 0.62, 0.16 }, { 0.62, 0.32, 0.12 } }) do
            local spot = round(frame(Color3.fromRGB(240, 196, 210), 0.65, moon))
            spot.AnchorPoint = Vector2.new(0.5, 0.5)
            spot.Position = UDim2.fromScale(m[1], m[2])
            spot.Size = UDim2.fromScale(m[3], m[3])
        end
    end

    -- sunset cloud streaks drifting across the sky
    local clouds = {}
    for i = 1, 9 do
        local c = round(frame(i % 3 == 0 and Color3.fromRGB(255, 196, 170) or Color3.fromRGB(240, 150, 180), 0))
        c.AnchorPoint = Vector2.new(0.5, 0.5)
        local w = rng:NextNumber(0.16, 0.34)
        c.Size = UDim2.fromScale(w, rng:NextNumber(0.005, 0.011))
        local g = Instance.new("UIGradient")
        g.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.35, 0.78), NumberSequenceKeypoint.new(0.65, 0.78),
            NumberSequenceKeypoint.new(1, 1),
        })
        g.Parent = c
        clouds[i] = { frame = c, x = rng:NextNumber(-0.1, 1.1), y = rng:NextNumber(0.3, 0.56), speed = rng:NextNumber(0.004, 0.01) }
    end

    -- mountain slices; colourFn(x, h) lets a layer shade itself
    local function range(count, x0, x1, heightFn, colourFn, transparency, mirror)
        local holder = frame(Color3.new(1, 1, 1), 1)
        holder.Size = UDim2.fromScale(1, 1)
        local width = (x1 - x0) / count
        for i = 0, count - 1 do
            local x = x0 + (i + 0.5) * width
            local h = heightFn(x)
            if h > 0.002 then
                local slice = frame(colourFn(x, h), transparency or 0, holder)
                if mirror then
                    slice.Position = UDim2.fromScale(x0 + i * width, HORIZON)
                    slice.Size = UDim2.new(width, 1, h * mirror, 0)
                else
                    slice.AnchorPoint = Vector2.new(0, 1)
                    slice.Position = UDim2.fromScale(x0 + i * width, HORIZON)
                    slice.Size = UDim2.new(width, 1, h, 0)
                end
            end
        end
        return holder
    end
    local function noise(x, seed)
        return math.sin(x * 7.3 + seed) * 0.5 + math.sin(x * 17.1 + seed * 2) * 0.25
            + math.sin(x * 41.7 + seed * 3) * 0.13 + math.sin(x * 97.3 + seed * 5) * 0.06
    end

    -- 1. far ridge, pale with distance
    range(360, 0, 1, function(x)
        return 0.095 + noise(x, 1.7) * 0.035
    end, function(_, h)
        return Color3.fromRGB(176, 120, 176):Lerp(Color3.fromRGB(210, 150, 186), math.clamp((0.13 - h) / 0.08, 0, 1))
    end)
    band(HORIZON - 0.04, 0.12, Color3.fromRGB(255, 190, 200), 0.5)

    -- 2. Mount Fuji: broad cone, flattened crater, lit on the moon side
    local FUJI_X, FUJI_W, FUJI_H = 0.32, 0.34, 0.36
    local function fuji(x)
        local t = 1 - math.abs(x - FUJI_X) / FUJI_W
        if t <= 0 then return 0 end
        local h = FUJI_H * t ^ 1.45
        local crown = FUJI_H * 0.92
        if h > crown then h = crown + (h - crown) * 0.22 end
        return h + math.sin(x * 160) * 0.0015
    end
    local function fujiColour(x, h)
        -- moonlight falls from the right; blend across the summit, no seam
        local lit = math.clamp((x - FUJI_X) / 0.06 * 0.5 + 0.5, 0, 1) * 0.25
        local base = Color3.fromRGB(92, 66, 128):Lerp(Color3.fromRGB(150, 98, 150), lit)
        return base:Lerp(Color3.fromRGB(196, 120, 150), math.clamp(1 - h / FUJI_H, 0, 1) * 0.55)
    end
    -- snow first at full height, then the rock drawn over it up to a ragged
    -- snowline, with gullies of snow left running down the slopes
    range(420, FUJI_X - FUJI_W, FUJI_X + FUJI_W, fuji, function(x)
        return Color3.fromRGB(226, 206, 232):Lerp(Color3.fromRGB(255, 246, 250), math.clamp((x - FUJI_X) / 0.06 * 0.5 + 0.5, 0, 1))
    end)
    range(420, FUJI_X - FUJI_W, FUJI_X + FUJI_W, function(x)
        local h = fuji(x)
        local hem = FUJI_H * 0.64 + math.sin(x * 130) * 0.012 + math.sin(x * 53 + 1) * 0.01
        local gully = math.abs(math.sin(x * 55)) ^ 8 * 0.035 * math.clamp(1 - math.abs(x - FUJI_X) / (FUJI_W * 0.6), 0, 1)
        return math.max(0, math.min(h, hem - gully))
    end, fujiColour)
    local mistA, mistAGrad = band(HORIZON - 0.05, 0.1, Color3.fromRGB(255, 196, 210), 0.42)

    -- 3. jagged mid range on the right
    range(300, 0.5, 1, function(x)
        local peaks = math.max(
            0.13 * math.max(0, 1 - math.abs(x - 0.66) / 0.14) ^ 1.2,
            0.17 * math.max(0, 1 - math.abs(x - 0.84) / 0.16) ^ 1.15,
            0.1 * math.max(0, 1 - math.abs(x - 0.98) / 0.1) ^ 1.2)
        return peaks + noise(x, 4.1) * 0.012 + 0.02
    end, function(x, h)
        return Color3.fromRGB(80, 50, 104):Lerp(Color3.fromRGB(124, 74, 124), math.clamp(1 - h / 0.17, 0, 1))
    end)
    band(HORIZON - 0.015, 0.06, Color3.fromRGB(255, 186, 200), 0.5)

    -- 4. near hills, crowned with a tree line and distant sakura
    local function hills(x)
        local left = 0.07 * math.max(0, 1 - x / 0.4) ^ 0.8
        local right = 0.06 * math.max(0, 1 - (1 - x) / 0.34) ^ 0.8
        return math.max(left, right, 0.008) + math.abs(math.sin(x * 210)) * 0.006 + math.abs(math.sin(x * 97)) * 0.004
    end
    range(400, 0, 1, hills, function(_, h)
        return Color3.fromRGB(46, 26, 58):Lerp(Color3.fromRGB(70, 38, 74), math.clamp(h / 0.07, 0, 1))
    end)

    -- buildings on the far shore: a five-storey pagoda in front of Fuji and
    -- a small house beside it with warm shoji windows. Everything is tinted
    -- toward the dusk haze so they sit back in the distance.
    local HAZE = Color3.fromRGB(150, 96, 140)
    local function hazed(c, amount) return c:Lerp(HAZE, amount or 0.3) end
    local function building(x, size)
        local holder = frame(Color3.new(1, 1, 1), 1)
        holder.AnchorPoint = Vector2.new(0.5, 1)
        holder.SizeConstraint = Enum.SizeConstraint.RelativeYY
        holder.Size = UDim2.fromScale(size, size)
        holder.Position = UDim2.fromScale(x, HORIZON - hills(x) + 0.006)
        return holder
    end
    local function block(holder, px, py, w, h, colour, rot, transparency)
        local b = frame(colour, transparency or 0, holder)
        b.AnchorPoint = Vector2.new(0.5, 0.5)
        b.Position = UDim2.fromScale(px, py)
        b.Size = UDim2.fromScale(w, h)
        b.Rotation = rot or 0
        return b
    end
    local function roof(holder, cy, width, colour)
        -- a tiled eave with flared, upturned corners
        block(holder, 0.5, cy, width, 0.035, colour)
        block(holder, 0.5, cy - 0.022, width * 0.82, 0.02, colour)
        block(holder, 0.5 - width / 2, cy - 0.01, width * 0.14, 0.022, colour, -14)
        block(holder, 0.5 + width / 2, cy - 0.01, width * 0.14, 0.022, colour, 14)
    end
    local windows = {}
    do
        -- pagoda: five tiers narrowing upward, a spire with rings on top
        local pagoda = building(0.333, 0.27)
        local wall = hazed(Color3.fromRGB(196, 70, 58), 0.32)
        local tile = hazed(Color3.fromRGB(38, 24, 42), 0.22)
        local y = 1
        for tier = 1, 5 do
            local w = 0.34 - tier * 0.04
            local h = tier == 1 and 0.13 or 0.1
            block(pagoda, 0.5, y - h / 2, w, h, wall)
            local win = block(pagoda, 0.5, y - h / 2, w * 0.3, h * 0.45, Color3.fromRGB(255, 196, 120), 0, 0.15)
            windows[#windows + 1] = win
            y = y - h
            roof(pagoda, y, w + 0.22 - tier * 0.012, tile)
            y = y - 0.035
        end
        block(pagoda, 0.5, y - 0.09, 0.012, 0.18, tile)                       -- sorin spire
        for k = 1, 5 do block(pagoda, 0.5, y - 0.03 - k * 0.026, 0.05, 0.008, tile) end
        block(pagoda, 0.5, 0.995, 0.36, 0.02, hazed(Color3.fromRGB(70, 56, 70), 0.3)) -- stone base
    end
    do
        -- house: white plaster walls, a dark irimoya roof, three lit shoji
        local house = building(0.268, 0.15)
        local plaster = hazed(Color3.fromRGB(236, 222, 214), 0.35)
        local timber = hazed(Color3.fromRGB(60, 40, 44), 0.25)
        local tile = hazed(Color3.fromRGB(34, 22, 38), 0.2)
        block(house, 0.5, 0.97, 0.86, 0.06, hazed(Color3.fromRGB(70, 56, 70), 0.3)) -- stone footing
        block(house, 0.5, 0.78, 0.74, 0.32, plaster)
        block(house, 0.5, 0.63, 0.76, 0.03, timber)                             -- beam
        for i = 0, 2 do
            local wx = 0.27 + i * 0.23
            local shoji = block(house, wx, 0.8, 0.17, 0.2, Color3.fromRGB(255, 206, 140), 0, 0.05)
            windows[#windows + 1] = shoji
            block(shoji, 0.5, 0.5, 0.08, 1, timber)                              -- muntins
            block(shoji, 0.5, 0.5, 1, 0.07, timber)
        end
        -- layered roof stepping up to a ridge, eaves flared at the corners
        block(house, 0.5, 0.58, 1.06, 0.06, tile)
        block(house, 0.5, 0.52, 0.86, 0.07, tile)
        block(house, 0.5, 0.46, 0.64, 0.06, tile)
        block(house, 0.5, 0.425, 0.48, 0.025, timber)                           -- ridge
        block(house, -0.01, 0.56, 0.14, 0.04, tile, -16)
        block(house, 1.01, 0.56, 0.14, 0.04, tile, 16)
    end
    -- warm light from the windows spilling onto the water
    softDisc(0.29, HORIZON + 0.012, 0.1, Color3.fromRGB(255, 190, 120), 8, 0.965)

    -- lake: mirrored Fuji, the moon path, a torii standing in the water
    range(210, FUJI_X - FUJI_W, FUJI_X + FUJI_W, fuji, function(x, h)
        -- solid, pre-blended with the water: translucent slices stripe where they overlap
        return fujiColour(x, h):Lerp(Color3.fromRGB(48, 28, 64), 0.72)
    end, 0, 0.55)
    local reflectBand, reflectGrad = band(HORIZON + 0.04, 0.08, Color3.fromRGB(255, 180, 196), 0.75)
    local shimmer = {}
    for i = 1, 26 do
        local y = HORIZON + 0.012 + (i / 26) ^ 1.35 * 0.27
        local dash = round(frame(Color3.fromRGB(255, 230, 236), 0.5))
        dash.AnchorPoint = Vector2.new(0.5, 0.5)
        local w = 0.012 + (i / 26) * 0.055
        dash.Position = UDim2.fromScale(MOON_X + rng:NextNumber(-0.012, 0.012), y)
        dash.Size = UDim2.new(w, 0, 0, 2)
        shimmer[i] = { frame = dash, phase = rng:NextNumber() * 6.28, w = w }
    end
    local function torii(y, alpha, flip)
        local t = frame(Color3.new(1, 1, 1), 1)
        t.AnchorPoint = Vector2.new(0.5, flip and 0 or 1)
        t.Position = UDim2.fromScale(0.67, y)
        t.Size = UDim2.fromScale(0.13, 0.13)
        t.SizeConstraint = Enum.SizeConstraint.RelativeYY
        local red, dark = Color3.fromRGB(214, 58, 52), Color3.fromRGB(34, 18, 26)
        local function piece(px, py, w, h, colour, rot)
            local p = frame(colour, alpha, t)
            p.AnchorPoint = Vector2.new(0.5, 0.5)
            p.Position = UDim2.fromScale(px, flip and 1 - py or py)
            p.Size = UDim2.fromScale(w, h)
            p.Rotation = (rot or 0) * (flip and -1 or 1)
        end
        piece(0.28, 0.6, 0.085, 0.8, red)
        piece(0.72, 0.6, 0.085, 0.8, red)
        piece(0.5, 0.36, 0.82, 0.07, red)
        piece(0.5, 0.17, 1.0, 0.09, red)
        piece(0.5, 0.09, 1.14, 0.08, dark)
        piece(0.04, 0.065, 0.12, 0.07, dark, -9)
        piece(0.96, 0.065, 0.12, 0.07, dark, 9)
        piece(0.5, 0.26, 0.07, 0.14, red)
        return t
    end
    torii(HORIZON + 0.05, 0.72, true)   -- reflection first, under the gate
    torii(HORIZON + 0.05, 0, false)

    -- sky lanterns drifting up off the water
    local lanterns = {}
    for i = 1, 8 do
        local lantern = frame(Color3.fromRGB(255, 168, 92), 0.05)
        lantern.AnchorPoint = Vector2.new(0.5, 0.5)
        lantern.Size = UDim2.fromOffset(9, 13)
        round(lantern, UDim.new(0, 4))
        local glow = Instance.new("UIStroke")
        glow.Color = Color3.fromRGB(255, 190, 110)
        glow.Thickness = 3
        glow.Transparency = 0.6
        glow.Parent = lantern
        local g = Instance.new("UIGradient")
        g.Rotation = 90
        g.Color = ColorSequence.new(Color3.fromRGB(255, 226, 150), Color3.fromRGB(255, 120, 70))
        g.Parent = lantern
        lanterns[i] = { frame = lantern, glow = glow, x = rng:NextNumber(0.06, 0.94), y = rng:NextNumber(0.35, 0.95),
            speed = rng:NextNumber(0.008, 0.018), phase = rng:NextNumber() * 6.28 }
    end

    -- shore banks along the bottom, strewn with fallen petals
    for _, spec in ipairs({ { 0.1, 1.02, 0.7, 0.2 }, { 0.92, 1.03, 0.6, 0.18 }, { 0.3, 1.06, 0.5, 0.14 } }) do
        local bank = round(frame(Color3.new(1, 1, 1), 0))
        bank.AnchorPoint = Vector2.new(0.5, 0.5)
        bank.Position = UDim2.fromScale(spec[1], spec[2])
        bank.Size = UDim2.fromScale(spec[3], spec[4])
        local g = Instance.new("UIGradient")
        g.Rotation = 90
        g.Color = ColorSequence.new(Color3.fromRGB(64, 36, 66), Color3.fromRGB(20, 12, 26))
        g.Parent = bank
    end
    for _ = 1, 90 do
        local left = rng:NextNumber() < 0.6
        local x = left and rng:NextNumber(0, 0.42) or rng:NextNumber(0.66, 1)
        local p = round(frame(PINKS[rng:NextInteger(1, #PINKS)], rng:NextNumber(0.05, 0.35)))
        p.AnchorPoint = Vector2.new(0.5, 0.5)
        local s = rng:NextNumber(4, 8)
        p.Size = UDim2.fromOffset(s, s * 0.6)
        p.Rotation = rng:NextNumber(0, 180)
        p.Position = UDim2.fromScale(x, rng:NextNumber(0.94, 1))
    end

    -- sakura trees: recursive branches, shaded blossom clusters at every tip,
    -- weeping strands of blossom hanging from the outer branches
    local trees, strands = {}, {}
    local function sakura(xScale, height, flip, seed, depth, baseY)
        local r = Random.new(seed)
        local tree = frame(Color3.new(1, 1, 1), 1)
        tree.AnchorPoint = Vector2.new(0.5, 1)
        tree.Position = UDim2.fromScale(xScale, baseY or 1.02)
        tree.Size = UDim2.fromScale(height, height)
        tree.SizeConstraint = Enum.SizeConstraint.RelativeYY
        local bark = Color3.fromRGB(44, 24, 34)
        local tips = {}
        local function limb(x, y, length, thickness, angle)
            local l = frame(bark, 0, tree)
            l.AnchorPoint = Vector2.new(0.5, 0.5)
            local rad = math.rad(angle)
            local dx, dy = math.sin(rad), -math.cos(rad)
            l.Position = UDim2.fromScale(x + dx * length / 2, y + dy * length / 2)
            l.Size = UDim2.fromScale(thickness, length + thickness * 0.5)
            l.Rotation = angle
            round(l, UDim.new(0.5, 0))
            local g = Instance.new("UIGradient")
            g.Color = ColorSequence.new(Color3.fromRGB(70, 40, 52), bark)
            g.Parent = l
            return x + dx * length, y + dy * length
        end
        local function grow(x, y, length, thickness, angle, level)
            local ex, ey = limb(x, y, length, thickness, angle)
            if level == 0 then
                tips[#tips + 1] = { ex, ey, angle }
                return
            end
            local children = level >= depth - 1 and 3 or r:NextInteger(2, 3)
            for c = 1, children do
                local spread = (c - (children + 1) / 2) * r:NextNumber(22, 34)
                local bend = (flip and -1 or 1) * r:NextNumber(4, 14)
                grow(ex, ey, length * r:NextNumber(0.66, 0.8), thickness * 0.66, angle + spread + bend, level - 1)
            end
        end
        local lean = flip and -14 or 14
        grow(0.5, 1, 0.3, 0.075, lean, depth)
        -- blossoms: a shadow layer under, the body, then highlights on top
        for pass = 1, 3 do
            for _, tip in ipairs(tips) do
                local count = pass == 1 and 5 or (pass == 2 and 8 or 3)
                for _ = 1, count do
                    local s = r:NextNumber(0.035, 0.075) * (pass == 3 and 0.6 or 1)
                    local colour = pass == 1 and BLOSSOM_SHADOW or (pass == 2 and PINKS[r:NextInteger(1, #PINKS)] or BLOSSOM_LIGHT)
                    local d = round(frame(colour, pass == 3 and 0.25 or r:NextNumber(0, 0.15), tree))
                    d.AnchorPoint = Vector2.new(0.5, 0.5)
                    d.Size = UDim2.fromScale(s, s)
                    local ox = r:NextNumber(-0.07, 0.07)
                    local oy = pass == 1 and r:NextNumber(-0.02, 0.06) or (pass == 3 and r:NextNumber(-0.07, 0) or r:NextNumber(-0.06, 0.04))
                    d.Position = UDim2.fromScale(tip[1] + ox, tip[2] + oy)
                end
            end
        end
        -- weeping strands from the outermost tips
        for i, tip in ipairs(tips) do
            if i % 3 == 0 then
                local dots = {}
                local len = r:NextInteger(5, 9)
                for k = 1, len do
                    local d = round(frame(PINKS[r:NextInteger(1, #PINKS)], 0.05 + k / len * 0.3, tree))
                    d.AnchorPoint = Vector2.new(0.5, 0.5)
                    local s = 0.026 - k * 0.0018
                    d.Size = UDim2.fromScale(s, s)
                    dots[k] = d
                end
                strands[#strands + 1] = { dots = dots, x = tip[1], y = tip[2] + 0.03, phase = r:NextNumber() * 6.28 }
            end
        end
        trees[#trees + 1] = { frame = tree, phase = seed }
    end
    -- a soft beam of moonlight laid across the water
    do
        local beam = frame(Color3.fromRGB(255, 226, 236), 0)
        beam.AnchorPoint = Vector2.new(0.5, 0)
        beam.Position = UDim2.fromScale(MOON_X, HORIZON)
        beam.Size = UDim2.fromScale(0.16, 0.32)
        local g = Instance.new("UIGradient")
        g.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0.86), NumberSequenceKeypoint.new(1, 1),
        })
        g.Parent = beam
    end

    -- the two great trees framing the view
    sakura(-0.04, 0.82, false, 11, 4)
    sakura(1.05, 0.76, true, 23, 4)

    -- a stone lantern (toro) on the near shore, its window lit
    local toroGlow
    do
        local holder = frame(Color3.new(1, 1, 1), 1)
        holder.AnchorPoint = Vector2.new(0.5, 1)
        holder.SizeConstraint = Enum.SizeConstraint.RelativeYY
        holder.Position = UDim2.fromScale(0.3, 0.985)
        holder.Size = UDim2.fromScale(0.09, 0.17)
        local stone, dark = Color3.fromRGB(96, 80, 104), Color3.fromRGB(50, 38, 58)
        local function block(px, py, w, h, colour, r)
            local b = frame(colour, 0, holder)
            b.AnchorPoint = Vector2.new(0.5, 0.5)
            b.Position = UDim2.fromScale(px, py)
            b.Size = UDim2.fromScale(w, h)
            if r then round(b, UDim.new(r, 0)) end
            local g = Instance.new("UIGradient")
            g.Color = ColorSequence.new(colour:Lerp(Color3.new(1, 1, 1), 0.12), colour:Lerp(Color3.new(0, 0, 0), 0.4))
            g.Parent = b
        end
        block(0.5, 0.96, 0.8, 0.08, dark, 0.2)
        block(0.5, 0.78, 0.28, 0.32, stone, 0.15)
        block(0.5, 0.6, 0.62, 0.06, dark, 0.2)
        block(0.5, 0.47, 0.5, 0.2, stone, 0.1)
        local window = round(frame(Color3.fromRGB(255, 196, 120), 0, holder), UDim.new(0.2, 0))
        window.AnchorPoint = Vector2.new(0.5, 0.5)
        window.Position = UDim2.fromScale(0.5, 0.47)
        window.Size = UDim2.fromScale(0.26, 0.12)
        toroGlow = Instance.new("UIStroke")
        toroGlow.Color = Color3.fromRGB(255, 190, 110)
        toroGlow.Thickness = 7
        toroGlow.Transparency = 0.5
        toroGlow.Parent = window
        block(0.5, 0.33, 0.9, 0.1, dark, 0.3)
        block(0.5, 0.25, 0.14, 0.08, dark, 1)
        softDisc(0.3, 0.9, 0.22, Color3.fromRGB(255, 190, 120), 10, 0.97)
    end

    -- glowing motes drifting around the trees
    local motes = {}
    for i = 1, 28 do
        local left = i % 2 == 0
        local m = round(frame(i % 3 == 0 and Color3.fromRGB(255, 220, 170) or Color3.fromRGB(255, 200, 226), 0.2))
        m.AnchorPoint = Vector2.new(0.5, 0.5)
        local s = rng:NextNumber(2, 4)
        m.Size = UDim2.fromOffset(s, s)
        local halo = Instance.new("UIStroke")
        halo.Color = m.BackgroundColor3
        halo.Thickness = s + 1
        halo.Transparency = 0.7
        halo.Parent = m
        motes[i] = { frame = m, halo = halo, x = left and rng:NextNumber(0.02, 0.3) or rng:NextNumber(0.72, 0.98),
            y = rng:NextNumber(0.25, 0.95), phase = rng:NextNumber() * 6.28, speed = rng:NextNumber(0.3, 0.7) }
    end

    -- falling petals
    local petals = {}
    for i = 1, 60 do
        local p = round(frame(PINKS[(i % #PINKS) + 1], rng:NextNumber(0, 0.2)))
        p.AnchorPoint = Vector2.new(0.5, 0.5)
        local s = rng:NextNumber(5, 9)
        p.Size = UDim2.fromOffset(s, s * 0.62)
        petals[i] = { frame = p, x = rng:NextNumber(-0.1, 1.1), y = rng:NextNumber(-0.1, 1.05),
            fall = rng:NextNumber(0.03, 0.07), drift = rng:NextNumber(0.02, 0.05),
            spin = rng:NextNumber(60, 200) * (rng:NextNumber() < 0.5 and -1 or 1), phase = rng:NextNumber() * 6.28 }
    end

    local vignette = frame(Color3.new(0, 0, 0), 0)
    vignette.Size = UDim2.fromScale(1, 1)
    do
        local g = Instance.new("UIGradient")
        g.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(0.2, 1),
            NumberSequenceKeypoint.new(0.8, 1), NumberSequenceKeypoint.new(1, 0.3),
        })
        g.Parent = vignette
    end

    local clock, wind = 0, 1
    local conn
    conn = RunService.RenderStepped:Connect(function(dt)
        if not scene.Parent then conn:Disconnect() return end
        if opts.active and not opts.active() then return end
        clock = clock + dt
        for _, s in ipairs(stars) do
            s.frame.BackgroundTransparency = 0.35 + 0.55 * (0.5 + 0.5 * math.sin(clock * s.speed + s.phase))
        end
        local breathe = 0.5 + 0.5 * math.sin(clock * 0.8)
        halo.Size = UDim2.fromScale(0.5 + breathe * 0.04, 0.5 + breathe * 0.04)
        for _, c in ipairs(clouds) do
            c.x = c.x + c.speed * dt
            if c.x > 1.25 then c.x = -0.25 end
            c.frame.Position = UDim2.fromScale(c.x, c.y)
        end
        for _, d in ipairs(shimmer) do
            local a = 0.5 + 0.5 * math.sin(clock * 2.4 + d.phase)
            d.frame.BackgroundTransparency = 0.25 + a * 0.6
            d.frame.Size = UDim2.new(d.w * (0.7 + a * 0.6), 0, 0, 2)
        end
        mistAGrad.Offset = Vector2.new(math.sin(clock * 0.2) * 0.05, 0)
        mistA.Position = UDim2.fromScale(math.sin(clock * 0.07) * 0.03, HORIZON - 0.05)
        reflectGrad.Offset = Vector2.new(0, math.sin(clock * 0.8) * 0.04)
        for _, l in ipairs(lanterns) do
            l.y = l.y - l.speed * dt
            if l.y < 0.12 then l.y = 0.98 l.x = rng:NextNumber(0.06, 0.94) end
            l.frame.Position = UDim2.fromScale(l.x + math.sin(clock * 0.6 + l.phase) * 0.01, l.y)
            local fade = math.clamp((l.y - 0.12) / 0.25, 0, 1)
            l.frame.BackgroundTransparency = 1 - fade * 0.95
            l.glow.Transparency = 1 - fade * (0.4 + 0.15 * math.sin(clock * 3 + l.phase))
        end
        for _, t in ipairs(trees) do
            t.frame.Rotation = math.sin(clock * 0.7 + t.phase) * 0.7 * wind
        end
        for i, w in ipairs(windows) do
            w.BackgroundTransparency = 0.06 + 0.12 * (0.5 + 0.5 * math.sin(clock * (2.1 + i * 0.37) + i))
        end
        for _, m in ipairs(motes) do
            m.frame.Position = UDim2.fromScale(m.x + math.sin(clock * m.speed + m.phase) * 0.02,
                m.y + math.sin(clock * m.speed * 0.7 + m.phase * 2) * 0.03)
            local tw = 0.5 + 0.5 * math.sin(clock * 2.5 + m.phase)
            m.frame.BackgroundTransparency = 0.1 + tw * 0.6
            m.halo.Transparency = 0.55 + tw * 0.4
        end
        if toroGlow then
            toroGlow.Transparency = 0.45 + 0.2 * (0.5 + 0.5 * math.sin(clock * 6.3) * math.sin(clock * 2.9))
        end
        for _, st in ipairs(strands) do
            for k, dot in ipairs(st.dots) do
                local sway = math.sin(clock * 1.3 + st.phase - k * 0.35) * 0.006 * k * (0.6 + wind * 0.4)
                dot.Position = UDim2.fromScale(st.x + sway, st.y + k * 0.022)
            end
        end
        for _, p in ipairs(petals) do
            p.y = p.y + p.fall * dt * (0.6 + wind * 0.4)
            p.x = p.x + (p.drift * wind + math.sin(clock * 1.3 + p.phase) * 0.02) * dt
            if p.y > 1.05 or p.x > 1.12 then
                p.y = rng:NextNumber(-0.1, 0)
                p.x = rng:NextNumber(-0.15, 1)
            end
            p.frame.Position = UDim2.fromScale(p.x, p.y)
            p.frame.Rotation = (p.frame.Rotation + p.spin * dt * (0.5 + wind * 0.5)) % 360
        end
    end)

    return {
        frame = scene,
        setSpeed = function(value) wind = value end,
        stop = function() if conn then conn:Disconnect() end end,
    }
end

----------------------------------------------------------------------
-- GAME LIBRARY
----------------------------------------------------------------------
local G = {}
do
    local Library = RS:WaitForChild("Library")
    local Client = Library:WaitForChild("Client")
    local function opt(parent, name)
        local ok, mod = pcall(function() return require(parent[name]) end)
        return ok and mod or nil
    end
    G.THINGS = workspace:WaitForChild("__THINGS")
    G.Network = require(Client.Network)
    G.Save = require(Client.Save)
    G.Directory = require(Library.Directory)
    G.Variables = require(Library.Variables)
    G.PlayerPet = require(Client.PlayerPet)
    G.CustomEggsCmds = require(Client.CustomEggsCmds)
    G.EggCmds = require(Client.EggCmds)
    G.CurrencyCmds = require(Client.CurrencyCmds)
    G.MapCmds = opt(Client, "MapCmds")
    G.UltimateCmds = opt(Client, "UltimateCmds")
    G.InstancingCmds = opt(Client, "InstancingCmds")
    G.InventoryCmds = opt(Client, "InventoryCmds")
    G.LootboxCmds = opt(Client, "LootboxCmds")
    G.FruitCmds = opt(Client, "FruitCmds")
    G.PotionCmds = opt(Client, "PotionCmds")
    G.PetCmds = opt(Client, "PetCmds")
    G.DaycareCmds = opt(Client, "DaycareCmds")
    G.ForeverPackCmds = opt(Client, "ForeverPackCmds")
    G.FlexibleFlagCmds = opt(Client, "FlexibleFlagCmds")
    G.SprinklerCmds = opt(Client, "SprinklerCmds")
    G.ZoneCmds = opt(Client, "ZoneCmds")
    G.RebirthCmds = opt(Client, "RebirthCmds")
    G.PTTypes = opt(Library.Types, "PumpkinTycoon")
    G.PTButtons = (function() local ok, m = pcall(function() return require(Client.PumpkinTycoonCmds.Buttons) end) return ok and m or nil end)()
    G.PTUpgrades = (function() local ok, m = pcall(function() return require(Client.PumpkinTycoonCmds.Upgrades) end) return ok and m or nil end)()
end

local function save() return G.Save.Get() end
local function hrp()
    local c = LocalPlayer.Character
    return c and c:FindFirstChild("HumanoidRootPart")
end
local function invoke(name, ...)
    local r = table.pack(pcall(G.Network.Invoke, name, ...))
    if not r[1] then return false, tostring(r[2]) end
    return r[2], r[3], r[4]
end
local function fire(name, ...) return pcall(G.Network.Fire, name, ...) end
local function commas(n)
    local s = tostring(math.floor(tonumber(n) or 0))
    return (s:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", ""))
end
local function short(n)
    n = tonumber(n) or 0
    for _, u in ipairs({ { 1e15, "q" }, { 1e12, "t" }, { 1e9, "b" }, { 1e6, "m" }, { 1e3, "k" } }) do
        if n >= u[1] then return ("%.2f%s"):format(n / u[1], u[2]):gsub("%.?0+([a-z])$", "%1") end
    end
    return tostring(math.floor(n))
end
local function inventoryItems()
    local ok, list = pcall(function() return G.InventoryCmds.Container():All() end)
    return ok and type(list) == "table" and list or {}
end
local function itemId(item)
    local ok, id = pcall(function() return item:GetId() end)
    return ok and id or nil
end
local function diamonds()
    local ls = LocalPlayer:FindFirstChild("leaderstats")
    for _, v in ipairs(ls and ls:GetChildren() or {}) do
        if v.Name:find("Diamonds") then return tonumber(v.Value) or 0 end
    end
    return 0
end
local function inInstance()
    local ok, id = pcall(function() return G.InstancingCmds and G.InstancingCmds.GetInstanceID() end)
    return ok and id or nil
end

----------------------------------------------------------------------
-- SETTINGS (saved per account)
----------------------------------------------------------------------
local Settings = { toggles = {}, values = {} }
local SETTINGS_FILE = ("PS99Hub/%d.json"):format(LocalPlayer.UserId)
do
    local ok, data = pcall(function()
        if isfile and isfile(SETTINGS_FILE) then return HttpService:JSONDecode(readfile(SETTINGS_FILE)) end
    end)
    if ok and type(data) == "table" then
        Settings.toggles = type(data.toggles) == "table" and data.toggles or {}
        Settings.values = type(data.values) == "table" and data.values or {}
    end
end
local saveQueued = false
local function persist()
    if saveQueued then return end
    saveQueued = true
    task.delay(0.5, function()
        saveQueued = false
        pcall(function()
            if makefolder and not (isfolder and isfolder("PS99Hub")) then makefolder("PS99Hub") end
            writefile(SETTINGS_FILE, HttpService:JSONEncode(Settings))
        end)
    end)
end

----------------------------------------------------------------------
-- STATE / LOG
----------------------------------------------------------------------
local S = {
    alive = true, on = {}, status = {}, eggs = 0, hatches = 0, perHatch = 0, t0 = os.clock(),
    hatchT0 = 0, eggsAtStart = 0, shrink = 1, target = "-",
    counts = { gifts = 0, relics = 0, presents = 0, balloons = 0, machines = 0, lootboxes = 0, fruits = 0,
        potions = 0, golden = 0, rainbow = 0, zones = 0, keys = 0, tycoon = 0 },
}
env.__PS99HUB_STATE = S
local function alive() return S.alive end
local function setStatus(key, text) S.status[key] = text end

-- teleport lock: only one feature moves the character at a time, and it
-- always puts you back where you were
local moving = false
local function withTeleport(fn)
    if moving then return false end
    local root = hrp()
    if not root then return false end
    moving = true
    local home = root.CFrame
    local ok, err = pcall(fn, root)
    pcall(function()
        root.Anchored = false
        root.AssemblyLinearVelocity = Vector3.zero
        root.CFrame = home
    end)
    moving = false
    if not ok then warn("[PS99 Hub] " .. tostring(err)) end
    return ok
end

----------------------------------------------------------------------
-- UI
----------------------------------------------------------------------
local UI = {}
env.__PS99HUB_UI = UI
local THEME = {
    bg = Color3.fromRGB(20, 10, 22), panel = Color3.fromRGB(32, 16, 34), surface = Color3.fromRGB(46, 22, 46),
    accent = Color3.fromRGB(255, 150, 190), on = Color3.fromRGB(232, 74, 84), text = Color3.fromRGB(255, 238, 244),
    muted = Color3.fromRGB(206, 160, 182), stroke = Color3.fromRGB(110, 56, 90), good = Color3.fromRGB(126, 224, 138),
    gold = Color3.fromRGB(255, 211, 61), bad = Color3.fromRGB(255, 96, 110),
}
do
    local function new(class, props, parent)
        local o = Instance.new(class)
        for k, v in pairs(props or {}) do o[k] = v end
        if parent then o.Parent = parent end
        return o
    end
    local function corner(o, r) return new("UICorner", { CornerRadius = UDim.new(0, r) }, o) end
    local function stroke(o, c, t, th)
        return new("UIStroke", { Color = c, Transparency = t or 0, Thickness = th or 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, o)
    end
    local function pad(o, l, r, t, b)
        return new("UIPadding", { PaddingLeft = UDim.new(0, l or 0), PaddingRight = UDim.new(0, r or 0),
            PaddingTop = UDim.new(0, t or 0), PaddingBottom = UDim.new(0, b or 0) }, o)
    end
    local function label(parent, props)
        local l = new("TextLabel", {
            BackgroundTransparency = 1, Font = props.font or Enum.Font.GothamMedium, TextSize = props.size or 12,
            TextColor3 = props.colour or THEME.text, TextXAlignment = props.align or Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd, RichText = props.rich == true, Text = props.text or "",
            Size = props.sz or UDim2.fromScale(1, 1), Position = props.pos or UDim2.new(), ZIndex = props.z or 1,
            AnchorPoint = props.anchor or Vector2.zero, TextWrapped = props.wrap == true,
            -- a faint dark outline keeps text readable over the see-through glass
            TextStrokeColor3 = Color3.fromRGB(16, 6, 20), TextStrokeTransparency = 0.72,
        }, parent)
        return l
    end
    UI.new, UI.corner, UI.stroke, UI.pad, UI.label = new, corner, stroke, pad, label

    -- glass: every see-through surface registers its base transparency so the
    -- "Glass opacity" slider can scale them all at once
    UI.glassItems = {}
    UI.glassLevel = tonumber(Settings.values.glass) or 100
    local function glassValue(base)
        local k = UI.glassLevel / 100
        return math.clamp(1 - (1 - base) * k, 0, 1)
    end
    function UI.glassAdd(obj)
        local base = obj.BackgroundTransparency
        UI.glassItems[#UI.glassItems + 1] = { obj = obj, base = base }
        obj.BackgroundTransparency = glassValue(base)
        return obj
    end
    function UI.setGlass(level)
        UI.glassLevel = level
        for i = #UI.glassItems, 1, -1 do
            local g = UI.glassItems[i]
            if g.obj.Parent then g.obj.BackgroundTransparency = glassValue(g.base) else table.remove(UI.glassItems, i) end
        end
    end
    -- PlayerGui on purpose: under gethui() the thread loses write access to
    -- the UI as soon as it calls back into the game's own modules
    local parent = LocalPlayer:WaitForChild("PlayerGui")
    pcall(function()
        for _, old in ipairs(gethui():GetChildren()) do if old.Name == "PS99Hub" then old:Destroy() end end
    end)
    for _, old in ipairs(parent:GetChildren()) do if old.Name == "PS99Hub" then old:Destroy() end end
    local gui = new("ScreenGui", { Name = "PS99Hub", ResetOnSpawn = false, IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 50 }, parent)
    UI.gui = gui
    local scale = new("UIScale", {}, gui)
    local function rescale()
        local cam = workspace.CurrentCamera
        local v = cam and cam.ViewportSize or Vector2.new(1280, 720)
        scale.Scale = math.clamp(math.min(v.X / 1280, v.Y / 760), 0.62, 1.25)
    end
    rescale()
    workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(rescale)

    -- window ---------------------------------------------------------
    local win = new("Frame", { Name = "Window", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(1000, 640), BackgroundColor3 = THEME.bg, BorderSizePixel = 0 }, gui)
    local winCorner = corner(win, 22)
    stroke(win, THEME.stroke, 0.15, 1.6)
    local halo = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.new(1, 12, 1, 12), BackgroundColor3 = THEME.accent, BackgroundTransparency = 0.93, ZIndex = 0 }, win)
    corner(halo, 28)
    UI.win = win

    -- the Sakura Dusk scene lives behind the glass, clipped to the window
    local sceneHost = new("CanvasGroup", { Name = "Scene", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 0 }, win)
    local sceneCorner = corner(sceneHost, 22)
    local function shown()
        return win.Visible and gui.Enabled
    end
    local sceneHandle = pdBuildScene(sceneHost, { active = shown })
    -- a light dusk wash keeps text readable without hiding the scene
    local wash = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = THEME.bg, BackgroundTransparency = 0.82, ZIndex = 1 }, win)
    corner(wash, 22)
    UI.wash = wash
    UI.glassAdd(wash)
    UI.sceneHandle = sceneHandle

    -- header
    local logo = new("Frame", { Position = UDim2.fromOffset(20, 18), Size = UDim2.fromOffset(54, 54), Rotation = -5,
        BackgroundColor3 = Color3.fromRGB(214, 52, 58), ZIndex = 3 }, win)
    corner(logo, 12)
    do
        local inner = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.new(1, -9, 1, -9), BackgroundTransparency = 1, ZIndex = 3 }, logo)
        corner(inner, 8)
        stroke(inner, Color3.fromRGB(255, 232, 214), 0.15, 1.4)
        label(logo, { text = "99", font = Enum.Font.GothamBlack, size = 22, colour = Color3.fromRGB(255, 236, 220),
            align = Enum.TextXAlignment.Center, pos = UDim2.fromOffset(0, -4), z = 4 })
        label(logo, { text = "ペット", font = Enum.Font.GothamBold, size = 8, colour = Color3.fromRGB(255, 220, 205),
            align = Enum.TextXAlignment.Center, sz = UDim2.new(1, 0, 0, 10), pos = UDim2.new(0, 0, 1, -16), z = 4 })
    end
    local title = label(win, { text = "桜  PET SIMULATOR 99", font = Enum.Font.GothamBlack, size = 22,
        sz = UDim2.fromOffset(420, 30), pos = UDim2.fromOffset(88, 18), z = 3 })
    local titleGrad = new("UIGradient", { Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, THEME.text), ColorSequenceKeypoint.new(0.5, THEME.accent), ColorSequenceKeypoint.new(1, THEME.on) }) }, title)
    local subtitle = label(win, { text = LocalPlayer.Name, size = 12, colour = THEME.muted,
        sz = UDim2.fromOffset(420, 18), pos = UDim2.fromOffset(89, 50), z = 3 })
    UI.subtitle = subtitle

    -- stat chips
    UI.chips = {}
    for i, name in ipairs({ "DIAMONDS", "EGGS / MIN", "UPTIME" }) do
        local chip = new("Frame", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -118 - (3 - i) * 136, 0, 20),
            Size = UDim2.fromOffset(128, 50), BackgroundColor3 = THEME.panel, BackgroundTransparency = 0.55, ZIndex = 3 }, win)
        corner(chip, 12)
        UI.glassAdd(chip)
        stroke(chip, THEME.stroke, 0.35)
        label(chip, { text = name, font = Enum.Font.GothamBold, size = 9, colour = THEME.muted,
            sz = UDim2.new(1, -20, 0, 14), pos = UDim2.fromOffset(12, 8), z = 4 })
        UI.chips[name] = label(chip, { text = "-", font = Enum.Font.GothamBlack, size = 16,
            colour = i == 1 and Color3.fromRGB(140, 210, 255) or (i == 2 and THEME.good or THEME.accent),
            sz = UDim2.new(1, -20, 0, 20), pos = UDim2.fromOffset(12, 23), z = 4 })
    end
    -- window buttons
    local function winButton(x, text)
        local b = new("TextButton", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, x, 0, 25),
            Size = UDim2.fromOffset(40, 40), BackgroundColor3 = THEME.panel, BackgroundTransparency = 0.5,
            Text = text, Font = Enum.Font.GothamBlack, TextSize = 16, TextColor3 = THEME.text, AutoButtonColor = false, ZIndex = 3 }, win)
        corner(b, 12)
        stroke(b, THEME.stroke, 0.4)
        return b
    end
    local fullBtn = winButton(-64, "▢")
    local minBtn = winButton(-18, "–")

    -- sidebar
    local sidebar = new("Frame", { Position = UDim2.fromOffset(18, 92), Size = UDim2.new(0, 188, 1, -110),
        BackgroundColor3 = THEME.panel, BackgroundTransparency = 0.62, ZIndex = 2 }, win)
    corner(sidebar, 18)
    UI.glassAdd(sidebar)
    stroke(sidebar, THEME.stroke, 0.5)
    local search = new("TextButton", { Position = UDim2.fromOffset(10, 10), Size = UDim2.new(1, -20, 0, 30),
        BackgroundColor3 = THEME.bg, BackgroundTransparency = 0.55, Text = "Search everything   `", TextXAlignment = Enum.TextXAlignment.Left,
        Font = Enum.Font.GothamMedium, TextSize = 12, TextColor3 = THEME.muted, AutoButtonColor = false, ZIndex = 3 }, sidebar)
    corner(search, 10)
    pad(search, 12)
    local tabList = new("Frame", { Position = UDim2.fromOffset(10, 50), Size = UDim2.new(1, -20, 1, -60), BackgroundTransparency = 1, ZIndex = 3 }, sidebar)
    new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, tabList)
    local glider = new("Frame", { AnchorPoint = Vector2.new(0, 0.5), Size = UDim2.fromOffset(4, 22), BackgroundColor3 = THEME.accent,
        Visible = false, ZIndex = 6 }, sidebar)
    corner(glider, 2)
    stroke(glider, THEME.accent, 0.6, 3)

    -- page surface
    local surface = new("Frame", { Position = UDim2.fromOffset(220, 92), Size = UDim2.new(1, -238, 1, -110),
        BackgroundColor3 = THEME.panel, BackgroundTransparency = 0.66, ZIndex = 2 }, win)
    corner(surface, 18)
    UI.glassAdd(surface)
    stroke(surface, THEME.stroke, 0.5)
    local caption = label(surface, { text = "", font = Enum.Font.GothamBlack, size = 14, colour = THEME.accent,
        sz = UDim2.new(1, -300, 0, 24), pos = UDim2.fromOffset(22, 14), z = 3 })
    UI.caption = caption
    local chipRow = new("Frame", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -16, 0, 13), Size = UDim2.fromOffset(0, 26),
        AutomaticSize = Enum.AutomaticSize.X, BackgroundTransparency = 1, ZIndex = 3 }, surface)
    new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8),
        HorizontalAlignment = Enum.HorizontalAlignment.Right, SortOrder = Enum.SortOrder.LayoutOrder }, chipRow)
    local function headerChip(text, order)
        local b = new("TextButton", { LayoutOrder = order, AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(0, 26),
            BackgroundColor3 = THEME.surface, BackgroundTransparency = 0.45, Text = text, Font = Enum.Font.GothamBold, TextSize = 11,
            TextColor3 = THEME.text, AutoButtonColor = false, RichText = true, ZIndex = 3 }, chipRow)
        corner(b, 13)
        stroke(b, THEME.accent, 0.5)
        pad(b, 12, 12)
        return b
    end
    local runChip = headerChip("ALL IDLE", 1)
    runChip:FindFirstChildOfClass("UIPadding").PaddingLeft = UDim.new(0, 20)
    local pulse = new("Frame", { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, -12, 0.5, 0), Size = UDim2.fromOffset(7, 7),
        BackgroundColor3 = THEME.muted, ZIndex = 4 }, runChip)
    corner(pulse, 4)
    local searchChip = headerChip('SEARCH  <font color="#cea0b6">[ ` ]</font>', 2)
    UI.runChip, UI.pulse = runChip, pulse

    -- tabs and pages -------------------------------------------------
    UI.tabs = {}
    UI.current = nil
    local function moveGlider(btn, instant)
        local sx = sidebar.AbsoluteSize.X / math.max(1, sidebar.Size.X.Offset)
        if btn.AbsoluteSize.Y < 2 or sx <= 0 then return end
        local y = (btn.AbsolutePosition.Y - sidebar.AbsolutePosition.Y + btn.AbsoluteSize.Y / 2) / sx
        local target = UDim2.fromOffset(3, y)
        if instant or not glider.Visible then
            glider.Position = target
            glider.Visible = true
        else
            TweenService:Create(glider, TweenInfo.new(0.12), { Size = UDim2.fromOffset(4, 34) }):Play()
            TweenService:Create(glider, TweenInfo.new(0.34, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Position = target }):Play()
            task.delay(0.14, function()
                TweenService:Create(glider, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Size = UDim2.fromOffset(4, 22) }):Play()
            end)
        end
    end
    function UI.select(tab, instant)
        for _, t in ipairs(UI.tabs) do
            local active = t == tab
            t.page.Visible = active
            t.button.BackgroundColor3 = active and THEME.accent or THEME.surface
            t.button.BackgroundTransparency = active and 0.08 or 0.7
            t.name.TextColor3 = active and Color3.fromRGB(40, 14, 30) or THEME.muted
            t.number.TextColor3 = active and Color3.fromRGB(40, 14, 30) or THEME.muted
        end
        UI.current = tab
        caption.Text = tab.title:upper()
        caption.MaxVisibleGraphemes = 0
        task.spawn(function()
            for n = 1, #caption.Text do
                if UI.current ~= tab then return end
                caption.MaxVisibleGraphemes = n
                task.wait(0.02)
            end
            caption.MaxVisibleGraphemes = -1
        end)
        local p = tab.page.Position
        tab.page.Position = p + UDim2.fromOffset(0, 14)
        TweenService:Create(tab.page, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Position = p }):Play()
        task.defer(moveGlider, tab.button, instant)
    end
    function UI.tab(title, order)
        local btn = new("TextButton", { LayoutOrder = order, Size = UDim2.new(1, 0, 0, 40), BackgroundColor3 = THEME.surface,
            BackgroundTransparency = 0.7, Text = "", AutoButtonColor = false, ZIndex = 4 }, tabList)
        corner(btn, 12)
        local number = label(btn, { text = ("%02d"):format(order), font = Enum.Font.GothamBold, size = 11, colour = THEME.muted,
            sz = UDim2.fromOffset(26, 40), pos = UDim2.fromOffset(14, 0), z = 5 })
        local name = label(btn, { text = title:upper(), font = Enum.Font.GothamBold, size = 12, colour = THEME.muted,
            sz = UDim2.new(1, -90, 1, 0), pos = UDim2.fromOffset(44, 0), z = 5 })
        local badge = new("TextLabel", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0), Size = UDim2.fromOffset(26, 18),
            BackgroundColor3 = Color3.fromRGB(46, 160, 90), Font = Enum.Font.GothamBold, TextSize = 10, TextColor3 = Color3.new(1, 1, 1),
            Visible = false, ZIndex = 5 }, btn)
        corner(badge, 9)
        local page = new("ScrollingFrame", { Position = UDim2.fromOffset(14, 48), Size = UDim2.new(1, -28, 1, -60),
            BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 4, ScrollBarImageColor3 = THEME.accent,
            CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, Visible = false, ZIndex = 3 }, surface)
        new("UIListLayout", { Padding = UDim.new(0, 12), SortOrder = Enum.SortOrder.LayoutOrder }, page)
        pad(page, 4, 12, 4, 24)
        local tab = { title = title, button = btn, page = page, name = name, number = number, badge = badge, toggles = {}, order = 0 }
        btn.MouseButton1Click:Connect(function() UI.select(tab) end)
        btn.MouseEnter:Connect(function()
            if UI.current ~= tab then TweenService:Create(name, TweenInfo.new(0.15), { Position = UDim2.fromOffset(50, 0) }):Play() end
        end)
        btn.MouseLeave:Connect(function() TweenService:Create(name, TweenInfo.new(0.18), { Position = UDim2.fromOffset(44, 0) }):Play() end)
        UI.tabs[#UI.tabs + 1] = tab
        return tab
    end

    -- section cards and rows ---------------------------------------
    UI.allToggles = {}
    function UI.section(tab, heading, dotColour)
        tab.order += 1
        local card = new("Frame", { LayoutOrder = tab.order, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundColor3 = THEME.surface, BackgroundTransparency = 0.78, ZIndex = 3 }, tab.page)
        corner(card, 14)
        stroke(card, THEME.stroke, 0.45)
        pad(card, 12, 12, 10, 12)
        new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, card)
        UI.glassAdd(card)
        local head = new("TextButton", { LayoutOrder = 0, Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1, Text = "",
            AutoButtonColor = false, ZIndex = 4 }, card)
        local dot = new("Frame", { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 2, 0.5, 0), Size = UDim2.fromOffset(7, 7),
            BackgroundColor3 = dotColour or THEME.accent, ZIndex = 5 }, head)
        corner(dot, 4)
        label(head, { text = heading:upper(), font = Enum.Font.GothamBold, size = 12, colour = THEME.text,
            pos = UDim2.fromOffset(16, 0), sz = UDim2.new(1, -40, 1, 0), z = 5 })
        local chevron = label(head, { text = "-", font = Enum.Font.GothamBold, size = 14, colour = THEME.muted,
            align = Enum.TextXAlignment.Center, anchor = Vector2.new(1, 0), pos = UDim2.new(1, 0, 0, 0), sz = UDim2.fromOffset(22, 22), z = 5 })
        -- click the heading to fold the card away; remembered between runs
        local foldKey = "fold_" .. tab.title .. "_" .. heading
        local folded = Settings.values[foldKey] == true
        local function applyFold(animate)
            for _, child in ipairs(card:GetChildren()) do
                if child:IsA("GuiObject") and child ~= head then child.Visible = not folded end
            end
            chevron.Text = folded and "+" or "-"
        end
        head.MouseButton1Click:Connect(function()
            folded = not folded
            Settings.values[foldKey] = folded or nil
            persist()
            applyFold(true)
        end)
        card.ChildAdded:Connect(function(child)
            if folded and child:IsA("GuiObject") and child ~= head then task.defer(function() child.Visible = false end) end
        end)
        task.defer(applyFold, false)
        return { frame = card, n = 0, tab = tab }
    end

    local function ripple(btn)
        local clip = btn:FindFirstChild("RippleClip")
        if not clip then
            clip = new("Frame", { Name = "RippleClip", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ClipsDescendants = true, ZIndex = btn.ZIndex }, btn)
        end
        local mouse = UIS:GetMouseLocation()
        local abs, size = btn.AbsolutePosition, btn.AbsoluteSize
        if size.X < 1 then return end
        local rel = mouse - abs
        local d = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(math.clamp(rel.X / size.X, 0, 1), math.clamp(rel.Y / size.Y, 0, 1)),
            Size = UDim2.fromOffset(0, 0), BackgroundColor3 = THEME.accent, BackgroundTransparency = 0.72, ZIndex = btn.ZIndex + 1 }, clip)
        corner(d, 999)
        local span = math.max(size.X, size.Y) * 2.2
        TweenService:Create(d, TweenInfo.new(0.55, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            { Size = UDim2.fromOffset(span, span), BackgroundTransparency = 1 }):Play()
        game:GetService("Debris"):AddItem(d, 0.6)
    end

    -- a switch row; key persists in settings; returns a handle
    function UI.toggle(section, key, title, desc, default, onChange)
        section.n += 1
        local tab = section.tab
        local row = new("TextButton", { LayoutOrder = section.n, Size = UDim2.new(1, 0, 0, desc and 46 or 36),
            BackgroundColor3 = THEME.panel, BackgroundTransparency = 0.62, Text = "", AutoButtonColor = false, ZIndex = 4 }, section.frame)
        corner(row, 10)
        UI.glassAdd(row)
        local rowStroke = stroke(row, THEME.stroke, 0.7)
        local bar = new("Frame", { Position = UDim2.new(0, 6, 0, 8), Size = UDim2.new(0, 3, 1, -16), BackgroundColor3 = THEME.on,
            BackgroundTransparency = 1, ZIndex = 5 }, row)
        corner(bar, 2)
        local name = label(row, { text = title, font = Enum.Font.GothamBold, size = 13, colour = THEME.muted,
            sz = UDim2.new(1, -110, 0, 18), pos = UDim2.fromOffset(16, desc and 6 or 9), z = 5 })
        local sub
        if desc then
            sub = label(row, { text = desc, font = Enum.Font.Gotham, size = 11, colour = THEME.muted,
                sz = UDim2.new(1, -110, 0, 14), pos = UDim2.fromOffset(16, 25), z = 5 })
            sub.TextTransparency = 0.2
        end
        -- pin: a small diamond; pinned switches also show up on the Pinned tab
        local pinBtn = new("TextButton", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -62, 0.5, 0), Size = UDim2.fromOffset(22, 22),
            BackgroundTransparency = 1, Text = "", ZIndex = 6 }, row)
        local gem = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(9, 9),
            Rotation = 45, BackgroundColor3 = THEME.gold, BackgroundTransparency = 1, ZIndex = 6 }, pinBtn)
        corner(gem, 2)
        local gemStroke = stroke(gem, THEME.muted, 0.4, 1.2)
        local function paintPin()
            local pinned = Settings.values["pin_" .. key] == true
            gem.BackgroundTransparency = pinned and 0 or 1
            gemStroke.Color = pinned and THEME.gold or THEME.muted
            gemStroke.Transparency = pinned and 0 or 0.4
        end
        paintPin()
        pinBtn.MouseButton1Click:Connect(function()
            Settings.values["pin_" .. key] = not (Settings.values["pin_" .. key] == true) or nil
            persist()
            paintPin()
            if UI.refreshPins then UI.refreshPins() end
        end)
        local track = new("Frame", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0), Size = UDim2.fromOffset(42, 22),
            BackgroundColor3 = THEME.surface, ZIndex = 5 }, row)
        corner(track, 11)
        stroke(track, THEME.stroke, 0.5)
        local knob = new("Frame", { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 3, 0.5, 0), Size = UDim2.fromOffset(16, 16),
            BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 6 }, track)
        corner(knob, 8)
        local squash = new("UIScale", {}, knob)
        local state = Settings.toggles[key]
        if state == nil then state = default == true end
        local handle = { key = key, title = title, desc = desc, tab = tab, row = row, paintPin = paintPin }
        local function paint(animate)
            local target = state and UDim2.new(1, -19, 0.5, 0) or UDim2.new(0, 3, 0.5, 0)
            if animate then
                TweenService:Create(knob, TweenInfo.new(0.26, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Position = target }):Play()
                squash.Scale = 1.3
                TweenService:Create(squash, TweenInfo.new(0.24), { Scale = 1 }):Play()
                TweenService:Create(track, TweenInfo.new(0.18), { BackgroundColor3 = state and THEME.on or THEME.surface }):Play()
            else
                knob.Position = target
                track.BackgroundColor3 = state and THEME.on or THEME.surface
            end
            bar.BackgroundTransparency = state and 0 or 1
            name.TextColor3 = state and THEME.text or THEME.muted
        end
        function handle.get() return state end
        function handle.set(v, animate)
            v = v == true
            if v == state then return end
            state = v
            Settings.toggles[key] = state
            persist()
            S.on[key] = state
            paint(animate)
            if onChange then task.spawn(pcall, onChange, state) end
        end
        function handle.flip() handle.set(not state, true) return state end
        row.MouseButton1Click:Connect(function() ripple(row) handle.flip() end)
        row.MouseEnter:Connect(function() rowStroke.Transparency = 0.3 rowStroke.Color = THEME.accent end)
        row.MouseLeave:Connect(function() rowStroke.Transparency = 0.7 rowStroke.Color = THEME.stroke end)
        S.on[key] = state
        paint(false)
        if state and onChange then task.defer(function() pcall(onChange, true) end) end
        tab.toggles[#tab.toggles + 1] = handle
        UI.allToggles[#UI.allToggles + 1] = handle
        UI.handles = UI.handles or {}
        UI.handles[key] = handle
        return handle
    end

    -- a live status line bound to S.status[key]
    UI.statusLines = {}
    function UI.status(section, key, initial)
        section.n += 1
        local l = label(section.frame, { text = initial or "", size = 11, colour = THEME.muted, sz = UDim2.new(1, 0, 0, 16), z = 4 })
        l.LayoutOrder = section.n
        pad(l, 16)
        UI.statusLines[#UI.statusLines + 1] = { label = l, key = key }
        return l
    end
    function UI.button(section, text, onClick)
        section.n += 1
        local b = new("TextButton", { LayoutOrder = section.n, Size = UDim2.new(1, 0, 0, 34), BackgroundColor3 = THEME.accent,
            Text = text, Font = Enum.Font.GothamBlack, TextSize = 12, TextColor3 = Color3.fromRGB(40, 14, 30), AutoButtonColor = true, ZIndex = 4 }, section.frame)
        corner(b, 10)
        b.MouseButton1Click:Connect(function() ripple(b) task.spawn(pcall, onClick) end)
        UI.actions = UI.actions or {}
        UI.actions[#UI.actions + 1] = { title = text, run = onClick, tab = section.tab }
        return b
    end
    function UI.slider(section, key, title, min, max, default, step, onChange)
        section.n += 1
        local row = new("Frame", { LayoutOrder = section.n, Size = UDim2.new(1, 0, 0, 46), BackgroundColor3 = THEME.panel,
            BackgroundTransparency = 0.62, ZIndex = 4 }, section.frame)
        corner(row, 10)
        local value = tonumber(Settings.values[key]) or default
        local name = label(row, { text = title, font = Enum.Font.GothamBold, size = 13, colour = THEME.text,
            sz = UDim2.new(1, -90, 0, 18), pos = UDim2.fromOffset(16, 6), z = 5 })
        local valueLabel = label(row, { text = tostring(value), font = Enum.Font.GothamBlack, size = 12, colour = THEME.accent,
            align = Enum.TextXAlignment.Right, sz = UDim2.fromOffset(70, 18), pos = UDim2.new(1, -82, 0, 6), z = 5 })
        local trackBar = new("TextButton", { Position = UDim2.fromOffset(16, 30), Size = UDim2.new(1, -32, 0, 6), Text = "",
            BackgroundColor3 = THEME.surface, AutoButtonColor = false, ZIndex = 5 }, row)
        corner(trackBar, 3)
        local fill = new("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = THEME.accent, ZIndex = 6 }, trackBar)
        corner(fill, 3)
        local function setValue(v, fromUser)
            v = math.clamp(math.floor(v / step + 0.5) * step, min, max)
            value = v
            fill.Size = UDim2.fromScale((v - min) / (max - min), 1)
            valueLabel.Text = tostring(v)
            if fromUser then Settings.values[key] = v persist() end
            if onChange then pcall(onChange, v) end
        end
        local dragging = false
        local function fromMouse()
            local x = UIS:GetMouseLocation().X
            local a, s = trackBar.AbsolutePosition.X, trackBar.AbsoluteSize.X
            setValue(min + (max - min) * math.clamp((x - a) / math.max(1, s), 0, 1), true)
        end
        trackBar.MouseButton1Down:Connect(function() dragging = true fromMouse() end)
        UIS.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end end)
        UIS.InputChanged:Connect(function(i) if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then fromMouse() end end)
        task.defer(setValue, value, false)
        UI.glassAdd(row)
        return { get = function() return value end }
    end

    -- a text input row; secret = only show the start of what is saved
    function UI.textbox(section, key, title, placeholder, secret)
        section.n += 1
        local row = new("Frame", { LayoutOrder = section.n, Size = UDim2.new(1, 0, 0, 58), BackgroundColor3 = THEME.panel,
            BackgroundTransparency = 0.62, ZIndex = 4 }, section.frame)
        corner(row, 10)
        UI.glassAdd(row)
        label(row, { text = title, font = Enum.Font.GothamBold, size = 13, colour = THEME.text, sz = UDim2.new(1, -32, 0, 18), pos = UDim2.fromOffset(16, 6), z = 5 })
        local box = new("TextBox", { Position = UDim2.fromOffset(12, 28), Size = UDim2.new(1, -24, 0, 24), BackgroundColor3 = THEME.bg,
            BackgroundTransparency = 0.35, ClearTextOnFocus = false, Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = THEME.text,
            PlaceholderText = placeholder or "", PlaceholderColor3 = THEME.muted, Text = "", TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 5 }, row)
        corner(box, 8)
        stroke(box, THEME.stroke, 0.5)
        pad(box, 8, 8)
        local function shown()
            local v = Settings.values[key]
            if type(v) ~= "string" or v == "" then return "" end
            if secret then return v:sub(1, 45) .. (#v > 45 and "  ••••••" or "") end
            return v
        end
        box.Text = shown()
        box.Focused:Connect(function() box.Text = type(Settings.values[key]) == "string" and Settings.values[key] or "" end)
        box.FocusLost:Connect(function()
            local v = box.Text:gsub("^%s+", ""):gsub("%s+$", "")
            Settings.values[key] = v ~= "" and v or nil
            persist()
            box.Text = shown()
        end)
        return box
    end

    -- a key binding row: click it, press a key, done (Backspace clears)
    UI.binds = {}
    function UI.keybind(section, key, title, default)
        section.n += 1
        local row = new("TextButton", { LayoutOrder = section.n, Size = UDim2.new(1, 0, 0, 36), BackgroundColor3 = THEME.panel,
            BackgroundTransparency = 0.62, Text = "", AutoButtonColor = false, ZIndex = 4 }, section.frame)
        corner(row, 10)
        UI.glassAdd(row)
        label(row, { text = title, font = Enum.Font.GothamBold, size = 13, colour = THEME.text,
            sz = UDim2.new(1, -150, 0, 18), pos = UDim2.fromOffset(16, 9), z = 5 })
        local cap = new("TextLabel", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0), Size = UDim2.fromOffset(0, 24),
            AutomaticSize = Enum.AutomaticSize.X, BackgroundColor3 = THEME.surface, BackgroundTransparency = 0.2, Font = Enum.Font.GothamBold,
            TextSize = 11, TextColor3 = THEME.accent, Text = "", ZIndex = 5 }, row)
        corner(cap, 8)
        stroke(cap, THEME.accent, 0.5)
        pad(cap, 10, 10)
        local function current()
            local name = Settings.values["key_" .. key]
            if name == false or name == "None" then return nil end
            local ok, code = pcall(function() return Enum.KeyCode[name or default] end)
            return ok and code or nil
        end
        local function paint() local k = current() cap.Text = k and k.Name:upper() or "NONE" end
        local listening = false
        row.MouseButton1Click:Connect(function()
            if listening then return end
            listening = true
            cap.Text = "PRESS A KEY..."
            local conn
            conn = UIS.InputBegan:Connect(function(input)
                if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
                conn:Disconnect()
                Settings.values["key_" .. key] = input.KeyCode == Enum.KeyCode.Backspace and "None" or input.KeyCode.Name
                persist()
                paint()
                task.delay(0.2, function() listening = false end)
            end)
        end)
        paint()
        UI.binds[key] = { get = current, busy = function() return listening end }
        return UI.binds[key]
    end

    -- toasts -----------------------------------------------------------
    local toastStack = new("Frame", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -16, 0, 70), Size = UDim2.fromOffset(300, 500),
        BackgroundTransparency = 1 }, gui)
    new("UIListLayout", { Padding = UDim.new(0, 8), HorizontalAlignment = Enum.HorizontalAlignment.Right, SortOrder = Enum.SortOrder.LayoutOrder }, toastStack)
    local toastN = 0
    UI.history = {}
    function UI.toast(titleText, body, colour)
        colour = colour or THEME.accent
        table.insert(UI.history, 1, { title = titleText, body = body, colour = colour, at = os.date("%H:%M:%S") })
        while #UI.history > 30 do table.remove(UI.history) end
        UI.unread = (UI.unread or 0) + 1
        if UI.onToast then pcall(UI.onToast) end
        toastN -= 1
        local card = new("Frame", { LayoutOrder = toastN, Size = UDim2.fromOffset(290, 58), BackgroundColor3 = THEME.bg }, toastStack)
        corner(card, 12)
        local cs = stroke(card, colour, 0.2, 1.5)
        local strip = new("Frame", { Position = UDim2.fromOffset(8, 8), Size = UDim2.new(0, 4, 1, -16), BackgroundColor3 = colour }, card)
        corner(strip, 2)
        label(card, { text = titleText, font = Enum.Font.GothamBlack, size = 14, colour = colour, sz = UDim2.new(1, -32, 0, 20), pos = UDim2.fromOffset(22, 8) })
        label(card, { text = body, font = Enum.Font.GothamMedium, size = 12, colour = THEME.text, sz = UDim2.new(1, -32, 0, 18), pos = UDim2.fromOffset(22, 30) })
        local timer = new("Frame", { AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 22, 1, -6), Size = UDim2.new(1, -36, 0, 2),
            BackgroundColor3 = colour, BackgroundTransparency = 0.35 }, card)
        local sc = new("UIScale", { Scale = 0.7 }, card)
        TweenService:Create(sc, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
        local hit = new("TextButton", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", ZIndex = 5 }, card)
        local gone = false
        local function dismiss()
            if gone then return end
            gone = true
            TweenService:Create(sc, TweenInfo.new(0.22), { Scale = 0.01 }):Play()
            game:GetService("Debris"):AddItem(card, 0.25)
        end
        local drain = TweenService:Create(timer, TweenInfo.new(6, Enum.EasingStyle.Linear), { Size = UDim2.new(0, 0, 0, 2) })
        drain:Play()
        drain.Completed:Connect(function(st) if st == Enum.PlaybackState.Completed then dismiss() end end)
        hit.MouseEnter:Connect(function() drain:Pause() cs.Transparency = 0 end)
        hit.MouseLeave:Connect(function() if not gone then drain:Play() end cs.Transparency = 0.2 end)
        hit.MouseButton1Click:Connect(dismiss)
    end

    -- window behaviour -------------------------------------------------
    local fullscreen = Settings.values.fullscreen == true
    local function applyFull()
        if fullscreen then
            -- scale-based sizes ignore the UIScale, so 1 x 1 centred is the whole screen
            win.AnchorPoint = Vector2.new(0.5, 0.5)
            win.Position = UDim2.fromScale(0.5, 0.5)
            win.Size = UDim2.fromScale(1, 1)
            -- cover the whole screen, top bar included; the logo and title slide
            -- right so Roblox's menu buttons in the corner don't sit on them
            gui.IgnoreGuiInset = true
            logo.Position = UDim2.fromOffset(176, 18)
            title.Position = UDim2.fromOffset(244, 18)
            subtitle.Position = UDim2.fromOffset(245, 50)
            winCorner.CornerRadius = UDim.new(0, 0)
            sceneCorner.CornerRadius = UDim.new(0, 0)
            halo.Visible = false
        else
            win.AnchorPoint = Vector2.new(0.5, 0.5)
            win.Position = UDim2.fromScale(0.5, 0.5)
            win.Size = UDim2.fromOffset(1000, 640)
            gui.IgnoreGuiInset = true
            logo.Position = UDim2.fromOffset(20, 18)
            title.Position = UDim2.fromOffset(88, 18)
            subtitle.Position = UDim2.fromOffset(89, 50)
            winCorner.CornerRadius = UDim.new(0, 22)
            sceneCorner.CornerRadius = UDim.new(0, 22)
            halo.Visible = true
        end
    end
    applyFull()
    scale:GetPropertyChangedSignal("Scale"):Connect(applyFull)
    local function flipFull()
        fullscreen = not fullscreen
        Settings.values.fullscreen = fullscreen
        persist()
        applyFull()
    end
    fullBtn.MouseButton1Click:Connect(flipFull)
    UI.toggleFullscreen = flipFull

    local curtain = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = THEME.bg, BackgroundTransparency = 1, ZIndex = 200 }, win)
    corner(curtain, 22)
    local function setVisible(v)
        win.Visible = v
        if v then
            curtain.BackgroundTransparency = 0
            TweenService:Create(curtain, TweenInfo.new(0.28), { BackgroundTransparency = 1 }):Play()
            if UI.current then task.defer(moveGlider, UI.current.button, true) end
        end
    end
    UI.setVisible = setVisible
    minBtn.MouseButton1Click:Connect(function() setVisible(false) end)

    -- drag the window by its header
    do
        local dragging, startPos, startMouse
        local dragZone = new("TextButton", { Size = UDim2.new(1, -560, 0, 84), Position = UDim2.fromOffset(84, 6), BackgroundTransparency = 1,
            Text = "", ZIndex = 2 }, win)
        dragZone.MouseButton1Down:Connect(function()
            if fullscreen then return end
            dragging, startPos, startMouse = true, win.Position, UIS:GetMouseLocation()
        end)
        UIS.InputChanged:Connect(function(i)
            if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
                local d = (UIS:GetMouseLocation() - startMouse) / scale.Scale
                win.Position = startPos + UDim2.fromOffset(d.X, d.Y)
            end
        end)
        UIS.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end end)
    end

    -- floating open button
    local openBtn = new("TextButton", { AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -18, 1, -18), Size = UDim2.fromOffset(56, 56),
        BackgroundColor3 = Color3.fromRGB(214, 52, 58), Text = "99", Font = Enum.Font.GothamBlack, TextSize = 18,
        TextColor3 = Color3.fromRGB(255, 236, 220), AutoButtonColor = false, ZIndex = 20 }, gui)
    corner(openBtn, 28)
    stroke(openBtn, THEME.accent, 0.3, 2)
    openBtn.MouseButton1Click:Connect(function() setVisible(not win.Visible) end)

    UI.searchButton, UI.searchChip = search, searchChip
    UI.sidebar, UI.moveGlider = sidebar, moveGlider
end

----------------------------------------------------------------------
-- COMMAND PALETTE ( ` )
----------------------------------------------------------------------
local Palette = {}
do
    local new, corner, stroke, label = UI.new, UI.corner, UI.stroke, UI.label
    local WIDTH, ROW_H, MAX_LIST = 620, 50, 430
    local backdrop = new("TextButton", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 1,
        Text = "", AutoButtonColor = false, Visible = false, ZIndex = 300 }, UI.gui)
    local shell = new("CanvasGroup", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0.14, 0), Size = UDim2.fromOffset(WIDTH, 200),
        BackgroundColor3 = THEME.bg, Visible = false, ZIndex = 301 }, UI.gui)
    corner(shell, 18)
    stroke(shell, THEME.accent, 0.4, 1.5)
    local pop = new("UIScale", {}, shell)
    local glow = new("Frame", { Size = UDim2.new(1, 0, 0, 120), BackgroundColor3 = THEME.accent, ZIndex = 301 }, shell)
    new("UIGradient", { Rotation = 90, Transparency = NumberSequence.new(0.75, 1) }, glow)
    local box = new("TextBox", { Position = UDim2.fromOffset(24, 9), Size = UDim2.new(1, -110, 0, 40), BackgroundTransparency = 1,
        ClearTextOnFocus = false, Font = Enum.Font.GothamMedium, TextSize = 19, TextColor3 = THEME.text, PlaceholderColor3 = THEME.muted,
        PlaceholderText = "Search features, tabs, actions...", Text = "", TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 302 }, shell)
    local esc = new("TextButton", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -18, 0, 18), Size = UDim2.fromOffset(46, 22),
        BackgroundColor3 = THEME.surface, Text = "ESC", Font = Enum.Font.GothamBold, TextSize = 11, TextColor3 = THEME.muted, ZIndex = 302 }, shell)
    corner(esc, 6)
    new("Frame", { Position = UDim2.fromOffset(16, 58), Size = UDim2.new(1, -32, 0, 1), BackgroundColor3 = THEME.stroke,
        BackgroundTransparency = 0.4, ZIndex = 302 }, shell)
    local list = new("ScrollingFrame", { Position = UDim2.fromOffset(8, 64), Size = UDim2.new(1, -16, 0, 100), BackgroundTransparency = 1,
        BorderSizePixel = 0, ScrollBarThickness = 3, ScrollBarImageColor3 = THEME.accent, CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y, ZIndex = 302 }, shell)
    new("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder }, list)
    UI.pad(list, 0, 6, 4, 6)
    local footer = label(shell, { text = "UP / DOWN  move    ENTER  run    ESC  close", font = Enum.Font.GothamBold, size = 10,
        colour = THEME.muted, sz = UDim2.new(1, -32, 0, 30), pos = UDim2.new(0, 16, 1, -32), z = 302 })

    local rows, selected, opened = {}, 1, false
    local function matchWord(word, text)
        local s = text:find(word, 1, true)
        if s then return 60 + #word * 4 + (s == 1 and 40 or 0) - s * 0.3 end
        local last, score, first = 0, 0, nil
        for i = 1, #word do
            local f = text:find(word:sub(i, i), last + 1, true)
            if not f then return nil end
            first = first or f
            if f == last + 1 then score += 6 end
            last = f
        end
        if last - first + 1 > #word * 2 + 2 then return nil end
        return score
    end
    local function items()
        local out = {}
        for _, t in ipairs(UI.allToggles) do
            out[#out + 1] = { kind = "toggle", title = t.title, sub = t.tab.title .. " tab", handle = t, tags = "switch " .. t.tab.title:lower() }
        end
        for _, t in ipairs(UI.tabs) do
            out[#out + 1] = { kind = "tab", title = t.title, sub = "Open this tab", tab = t, tags = "tab page" }
        end
        for _, a in ipairs(UI.actions or {}) do
            out[#out + 1] = { kind = "action", title = a.title, sub = a.tab.title .. " action", run = a.run, tags = "action button" }
        end
        out[#out + 1] = { kind = "action", title = "Toggle fullscreen", sub = "Window size", run = UI.toggleFullscreen, tags = "window" }
        return out
    end
    local function paint()
        for i, r in ipairs(rows) do
            r.frame.BackgroundTransparency = i == selected and 0.84 or 1
            r.bar.BackgroundTransparency = i == selected and 0 or 1
        end
    end
    local close
    local function run(r)
        local it = r.item
        if it.kind == "toggle" then
            local st = it.handle.flip()
            r.switch.BackgroundColor3 = st and THEME.on or THEME.surface
        elseif it.kind == "tab" then
            close()
            UI.setVisible(true)
            UI.select(it.tab)
        else
            close()
            task.spawn(pcall, it.run)
        end
    end
    local function refresh()
        for _, c in ipairs(list:GetChildren()) do if c:IsA("GuiObject") then c:Destroy() end end
        rows = {}
        local q = box.Text:lower():gsub("`", ""):gsub("^%s+", ""):gsub("%s+$", "")
        local scored = {}
        for _, it in ipairs(items()) do
            local total, ok = 0, true
            if q == "" then
                ok = it.kind == "toggle" and it.handle.get() or it.kind == "tab"
                total = it.kind == "toggle" and 100 or 0
            else
                for word in q:gmatch("%S+") do
                    local s = matchWord(word, it.title:lower())
                    if not s and it.tags:find(word, 1, true) then s = 20 end
                    if not s then ok = false break end
                    total += s
                end
            end
            if ok then scored[#scored + 1] = { it = it, s = total } end
        end
        table.sort(scored, function(a, b) if a.s ~= b.s then return a.s > b.s end return a.it.title < b.it.title end)
        for i = 1, math.min(#scored, 60) do
            local it = scored[i].it
            local f = new("TextButton", { LayoutOrder = i, Size = UDim2.new(1, 0, 0, ROW_H), BackgroundColor3 = THEME.accent,
                BackgroundTransparency = 1, Text = "", AutoButtonColor = false, ZIndex = 303 }, list)
            corner(f, 12)
            local bar = new("Frame", { Position = UDim2.new(0, 3, 0.5, -11), Size = UDim2.fromOffset(3, 22), BackgroundColor3 = THEME.accent,
                BackgroundTransparency = 1, ZIndex = 304 }, f)
            corner(bar, 2)
            label(f, { text = it.title, font = Enum.Font.GothamSemibold, size = 14, sz = UDim2.new(1, -120, 0, 18), pos = UDim2.fromOffset(18, 8), z = 304 })
            label(f, { text = it.sub, font = Enum.Font.Gotham, size = 11, colour = THEME.muted, sz = UDim2.new(1, -120, 0, 14), pos = UDim2.fromOffset(18, 27), z = 304 })
            local r = { frame = f, bar = bar, item = it }
            if it.kind == "toggle" then
                r.switch = new("Frame", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -14, 0.5, 0), Size = UDim2.fromOffset(36, 20),
                    BackgroundColor3 = it.handle.get() and THEME.on or THEME.surface, ZIndex = 304 }, f)
                corner(r.switch, 10)
            else
                label(f, { text = it.kind:upper(), font = Enum.Font.GothamBold, size = 10, colour = THEME.muted, align = Enum.TextXAlignment.Right,
                    sz = UDim2.fromOffset(70, ROW_H), pos = UDim2.new(1, -84, 0, 0), z = 304 })
            end
            rows[#rows + 1] = r
            local idx = #rows
            f.MouseEnter:Connect(function() selected = idx paint() end)
            f.MouseButton1Click:Connect(function() selected = idx paint() run(r) end)
        end
        local h = math.clamp(#rows * (ROW_H + 2) + 12, 60, MAX_LIST)
        list.Size = UDim2.new(1, -16, 0, h)
        shell.Size = UDim2.fromOffset(WIDTH, 64 + h + 36)
        selected = 1
        paint()
    end
    local function open()
        if opened then box:CaptureFocus() return end
        opened = true
        box.Text = ""
        refresh()
        backdrop.Visible, shell.Visible = true, true
        backdrop.BackgroundTransparency = 1
        TweenService:Create(backdrop, TweenInfo.new(0.2), { BackgroundTransparency = 0.5 }):Play()
        pop.Scale = 0.94
        TweenService:Create(pop, TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
        task.delay(0.05, function() if opened then box:CaptureFocus() task.defer(function() box.Text = box.Text:gsub("`", "") end) end end)
    end
    close = function()
        if not opened then return end
        opened = false
        pcall(function() box:ReleaseFocus() end)
        backdrop.Visible, shell.Visible = false, false
    end
    Palette.open, Palette.close = open, close
    backdrop.MouseButton1Click:Connect(close)
    esc.MouseButton1Click:Connect(close)
    box:GetPropertyChangedSignal("Text"):Connect(function() if opened then refresh() end end)
    box.FocusLost:Connect(function(enter)
        if not opened then return end
        if enter then
            if rows[selected] then run(rows[selected]) end
            if opened then task.defer(function() if opened then box:CaptureFocus() end end) end
        elseif UIS:IsKeyDown(Enum.KeyCode.Escape) then
            close()
        end
    end)
    UIS.InputBegan:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
        if opened then
            if input.KeyCode == Enum.KeyCode.Down then selected = math.min(#rows, selected + 1) paint()
            elseif input.KeyCode == Enum.KeyCode.Up then selected = math.max(1, selected - 1) paint()
            elseif input.KeyCode == Enum.KeyCode.Escape then close() end
            return
        end
        local bind = UI.binds and UI.binds.palette
        if bind and bind.busy() then return end
        local key = bind and bind.get() or (not bind and Enum.KeyCode.Backquote)
        if key and input.KeyCode == key and not UIS:GetFocusedTextBox() then open() end
    end)
    UI.searchButton.MouseButton1Click:Connect(open)
    UI.searchChip.MouseButton1Click:Connect(open)
    UI.runChip.MouseButton1Click:Connect(open)
end

----------------------------------------------------------------------
-- FEATURES
----------------------------------------------------------------------
local F = {}
local Tycoon = {}
env.__PS99HUB_TYCOON = Tycoon

-- loops run every `interval` seconds while their switch is on
local loops = {}
local function loop(key, interval, fn)
    loops[#loops + 1] = { key = key, interval = interval, fn = fn, next = 0 }
end
task.spawn(function()
    while alive() do
        local now = os.clock()
        for _, l in ipairs(loops) do
            if S.on[l.key] and now >= l.next and not l.running then
                l.next = now + l.interval
                l.running = true
                task.spawn(function()
                    local ok, err = pcall(l.fn)
                    if not ok then setStatus(l.key, "error: " .. tostring(err):sub(1, 80)) end
                    l.running = false
                end)
            end
        end
        task.wait(0.25)
    end
end)

-- AUTO HATCH ---------------------------------------------------------
do
    local REGULAR_RANGE = 30
    local function eggDir(name)
        local ok, d = pcall(function() return G.Directory.Eggs[name] end)
        return ok and d or nil
    end
    local function nearestEgg()
        local root = hrp()
        if not root then return nil end
        local pos, best, bestD = root.Position, nil, nil
        for _, e in pairs(G.CustomEggsCmds.All()) do
            local okH, hatchable = pcall(function() return e:IsHatchable() end)
            if okH and hatchable then
                local d = (e._position - pos).Magnitude
                if not bestD or d < bestD then bestD, best = d, { kind = "custom", id = e._id, key = e._uid, dir = e._dir, max = e._maxEggCount } end
            end
        end
        local folder = G.THINGS:FindFirstChild("Eggs")
        if folder then
            for _, m in ipairs(folder:GetChildren()) do
                local dir = m:IsA("Model") and eggDir(m.Name)
                if dir then
                    local okP, p = pcall(function() return m:GetPivot().Position end)
                    if okP then
                        local d = (p - pos).Magnitude
                        local okL, locked = pcall(G.EggCmds.IsEggLocked, m.Name)
                        if d <= REGULAR_RANGE and not (okL and locked) and (not bestD or d < bestD) then
                            bestD, best = d, { kind = "regular", id = m.Name, key = m.Name, dir = dir }
                        end
                    end
                end
            end
        end
        return best
    end
    local function amountFor(egg)
        local dir = egg.dir
        local maxHatch = egg.max or G.EggCmds.GetMaxHatch(dir)
        local amount = maxHatch
        local price = dir.overrideCost or dir.cost or dir.price
        if dir.currency and type(price) == "number" and price > 0 then
            local ok, have = pcall(G.CurrencyCmds.Get, dir.currency)
            if ok and type(have) == "number" then amount = math.min(maxHatch, math.floor(have / price)) end
        end
        return math.max(0, math.floor(amount / S.shrink))
    end
    F.nearestEgg = nearestEgg
    local running = false
    function F.startHatch()
        if running then return end
        running = true
        task.spawn(function()
            local t = os.clock()
            while G.Variables.OpeningEgg > 0 and os.clock() - t < 10 do task.wait(0.1) end
            G.Variables.OpeningEgg = 1
            S.hatchT0, S.eggsAtStart = os.clock(), S.eggs
            while S.on.hatch and alive() do
                local egg = nearestEgg()
                if not egg then
                    S.target = "-"
                    setStatus("hatch", "No egg in range - stand next to one")
                    task.wait(0.25)
                else
                    S.target = egg.id
                    local amount = amountFor(egg)
                    if amount < 1 then
                        setStatus("hatch", "Can't afford " .. egg.id)
                        task.wait(1)
                    else
                        if G.Variables.OpeningEgg < 1 then G.Variables.OpeningEgg = 1 end
                        S.perHatch = amount
                        local okH, success, err
                        if egg.kind == "custom" then
                            okH, success, err = pcall(G.Network.Invoke, "CustomEggs_Hatch", egg.key, amount)
                        else
                            okH, success, err = pcall(G.Network.Invoke, "Eggs_RequestPurchase", egg.key, amount)
                        end
                        if okH and success then
                            S.eggs += amount
                            S.hatches += 1
                            S.shrink = 1
                            setStatus("hatch", ("Hatching %s  ·  %d per hatch  ·  %s eggs"):format(egg.id, amount, commas(S.eggs)))
                        else
                            local msg = tostring(err or ""):lower()
                            if msg:find("enough") or msg:find("afford") or msg:find("more") then S.shrink = math.min(S.shrink * 2, 64) end
                            task.wait(okH and 0.05 or 0.25)
                        end
                    end
                end
            end
            task.wait(0.6)
            if not S.on.hatch then G.Variables.OpeningEgg = 0 setStatus("hatch", "Off") end
            running = false
        end)
    end
end

-- FAST FARM ------------------------------------------------------------
do
    local BREAK_RANGE = 100
    if not env.__PS99HUB_SPEED_HOOKED and hookfunction then
        env.__PS99HUB_SPEED_HOOKED = true
        local old
        old = hookfunction(G.PlayerPet.CalculateSpeedMultiplier, function(...)
            if env.__PS99HUB_FARM_ON then return 200 end
            return old(...)
        end)
    end
    local running = false
    function F.startFarm()
        if running then return end
        running = true
        task.spawn(function()
            local breakFolder = G.THINGS:WaitForChild("Breakables", 10)
            local lootFolder = G.THINGS:FindFirstChild("Lootbags")
            local orbFolder = G.THINGS:FindFirstChild("Orbs")
            local conns = {}
            local function claim(folder, eventName)
                if not folder then return end
                for _, item in ipairs(folder:GetChildren()) do pcall(G.Network.Fire, eventName, { item.Name }) end
                conns[#conns + 1] = folder.ChildAdded:Connect(function(item)
                    task.wait()
                    pcall(function() G.Network.Fire(eventName, { item.Name }) item:Destroy() end)
                end)
            end
            claim(lootFolder, "Lootbags_Claim")
            claim(orbFolder, "Orbs: Collect")
            env.__PS99HUB_FARM_ON = true
            local hits = 0
            while S.on.farm and alive() and breakFolder do
                task.wait()
                while S.on.tycoonfarm and S.on.farm and alive() and Tycoon.plot() do
                    setStatus("farm", "Paused - Tycoon Zone Farm is running")
                    task.wait(1)
                end
                local root = hrp()
                local valid = {}
                if root then
                    for _, b in ipairs(breakFolder:GetChildren()) do
                        if b:IsA("Model") and b.PrimaryPart and (root.Position - b.PrimaryPart.Position).Magnitude <= BREAK_RANGE then
                            valid[#valid + 1] = b.Name
                        end
                    end
                end
                local pets = {}
                for id in pairs(G.PlayerPet.GetAll()) do pets[#pets + 1] = tostring(id) end
                if #valid > 0 and #pets > 0 then
                    local target = valid[math.random(#valid)]
                    pcall(G.Network.UnreliableFire, "Breakables_PlayerDealDamage", target)
                    pcall(G.Network.Fire, "Breakables_JoinPetBulk", { { [target] = pets } })
                    hits += 1
                    if hits % 30 == 0 then setStatus("farm", ("Farming %d breakables in range  ·  %d pets"):format(#valid, #pets)) end
                else
                    setStatus("farm", "No breakables within 100 studs")
                    task.wait(0.5)
                end
            end
            env.__PS99HUB_FARM_ON = false
            for _, c in ipairs(conns) do c:Disconnect() end
            setStatus("farm", "Off")
            running = false
        end)
    end
end

-- AUTO ULTIMATE (amulet, R) ----------------------------------------
do
    local function equipped()
        local ok, item = pcall(function() return G.UltimateCmds.GetEquippedItem() end)
        if not ok or not item then return nil end
        local okId, id = pcall(function() return item:GetId() end)
        return okId and id or nil
    end
    local function inBreakZone()
        local root = hrp()
        if not root or not G.MapCmds then return false end
        local ok, padPart = pcall(function() return G.MapCmds.GetCurrentBreakZonePart() end)
        if not ok or not padPart then return false end
        local okIn, inside = pcall(function() return G.MapCmds.IsPositionInBreakZone(padPart, root.Position) end)
        return not okIn or inside ~= false
    end
    loop("ultimate", 0.4, function()
        local id = equipped()
        if not id then return setStatus("ultimate", "No ultimate equipped") end
        local okA, active = pcall(function() return G.UltimateCmds.IsActive() end)
        if okA and active then return setStatus("ultimate", id .. " active") end
        if not inBreakZone() then return setStatus("ultimate", "Not in a breakable zone") end
        local okC, charged = pcall(function() return G.UltimateCmds.IsCharged(id) end)
        if not (okC and charged) then return setStatus("ultimate", id .. " charging...") end
        if pcall(function() G.UltimateCmds.Activate(id) end) then
            setStatus("ultimate", "Used " .. id)
            task.wait(3)
        end
    end)
end

-- PUMPKIN TYCOON (event) -----------------------------------------------
-- Buttons and upgrades are bought through your own plot object
-- (plot:Invoke(verb, id)), not through the Network module. Breakables on
-- the island carry AreaID "<Section>_Zone_<plot>", so the farm locks onto
-- the highest zone you own and moves up as soon as a new one is bought.
do
    local T
    local function mods()
        if T then return T end
        local ok, m = pcall(function()
            local Lib = RS.Library
            return {
                Cmds = require(Lib.Client.PumpkinTycoonCmds),
                Island = require(Lib.Client.PumpkinTycoonCmds.Island),
                ButtonsClient = require(Lib.Client.PumpkinTycoonCmds.Buttons),
                UpgradesClient = require(Lib.Client.PumpkinTycoonCmds.Upgrades),
                Types = require(Lib.Types.PumpkinTycoon),
                Buttons = require(Lib.Types.PumpkinTycoon.Buttons),
                Upgrades = require(Lib.Types.PumpkinTycoon.Upgrades),
                Util = require(Lib.Util.PumpkinTycoonButtons),
                UpUtil = require(Lib.Util.PumpkinTycoonUpgrades),
                Items = require(Lib.Items),
            }
        end)
        if ok then T = m end
        return T
    end
    -- farming first: these make the zone farm faster, the rest come after
    local UPGRADE_ORDER = { "PumpkinCoins", "PumpkinDamage", "SpawnLuck", "RespawnSpeed", "EggLuck", "ChaseOdds", "StockSlots", "MerchantLuck" }

    function Tycoon.plot()
        local m = mods()
        if not m then return nil end
        local okI, inst = pcall(m.Cmds.Instance)
        if not (okI and inst) then return nil end
        local okP, plot = pcall(m.Island.Plot)
        if not (okP and plot) then return nil end
        local okM, model = pcall(function() return plot:GetModel() end)
        if not (okM and model) then return nil end
        return plot, model, m
    end
    function Tycoon.coins(m)
        local ok, n = pcall(function() return m.Items.Currency(m.Types.COIN):CountAny() end)
        return ok and tonumber(n) or 0
    end
    function Tycoon.state(plot, m)
        local ok, st = pcall(function() return plot:Save(m.Types.VAR.Buttons) end)
        return ok and st or nil
    end
    function Tycoon.zoneCount(m)
        local ok, p2 = pcall(m.Cmds.Part2)
        local part2 = ok and p2 == true
        return part2 and #m.Types.ZONES or m.Types.PART1_ZONES, part2
    end
    -- highest zone you own = the best paying one
    function Tycoon.bestZone()
        local plot, model, m = Tycoon.plot()
        if not plot then return nil end
        local st = Tycoon.state(plot, m)
        local count = Tycoon.zoneCount(m)
        local ok, idx = pcall(m.Util.FarmZone, st, count)
        if not (ok and idx) then return nil end
        local okS, slab = pcall(m.Util.ZoneSlab, model, idx)
        return idx, m.Types.ZONES[idx].Section, okS and slab or nil, m.Types.ZONES[idx].DisplayName, m.Types.ZONES[idx].Egg
    end

    -- the spot on the zone floor that is closest to that zone's egg, so you
    -- farm the zone and can hatch its egg from the same place
    function Tycoon.standSpot(slab, eggName)
        local eggPos
        pcall(function()
            for _, e in pairs(G.CustomEggsCmds.All()) do
                if e._id == eggName then eggPos = e._position break end
            end
        end)
        local top = slab.Size.Y / 2 + 3
        if not eggPos then return slab.CFrame * CFrame.new(0, top, 0), nil end
        local margin = 3
        local rel = slab.CFrame:PointToObjectSpace(eggPos)
        local hx, hz = math.max(0, slab.Size.X / 2 - margin), math.max(0, slab.Size.Z / 2 - margin)
        local spot = slab.CFrame:PointToWorldSpace(Vector3.new(math.clamp(rel.X, -hx, hx), top, math.clamp(rel.Z, -hz, hz)))
        local face = Vector3.new(eggPos.X, spot.Y, eggPos.Z)
        if (face - spot).Magnitude < 0.5 then return CFrame.new(spot), eggPos end
        return CFrame.lookAt(spot, face), eggPos
    end
    -- the next things you can buy, cheapest first
    local function buyable(plot, m)
        local st = Tycoon.state(plot, m)
        if type(st) ~= "table" then return {}, 0 end
        local count, part2 = Tycoon.zoneCount(m)
        local okM, mult = pcall(m.ButtonsClient.PriceMult)
        mult = okM and mult or nil
        local list, waiting = {}, nil
        for _, b in ipairs(m.Buttons.BUTTONS) do
            if b.Id ~= m.Buttons.REBIRTH_PAD then
                local okV, vis = pcall(m.Util.Visible, st, b, count, part2)
                if okV and vis then
                    local okP, price = pcall(m.Util.Price, b, mult)
                    if okP and type(price) == "number" then
                        list[#list + 1] = { button = b, price = price }
                    end
                end
            end
        end
        table.sort(list, function(a, b) return a.price < b.price end)
        return list
    end

    local function opensBreakArea(b)
        return type(b.Id) == "string" and (b.Id:match("_Zone$") ~= nil)
    end

    loop("tycoon", 0.5, function()
        local plot, _, m = Tycoon.plot()
        if not plot then return setStatus("tycoon", "Join the Pumpkin Tycoon event to use this") end
        local list = buyable(plot, m)
        local coins = Tycoon.coins(m)
        local boughtNow = 0
        for _, entry in ipairs(list) do
            if not S.on.tycoon then break end
            if entry.price > coins then break end
            local ok, success, reason = pcall(function() return plot:Invoke(m.Buttons.VERB_BUY, entry.button.Id) end)
            if ok and success == true then
                boughtNow += 1
                S.counts.tycoon += 1
                coins = Tycoon.coins(m)
                setStatus("tycoon", ("Bought %s  ·  %d this session"):format(entry.button.Display or entry.button.Id, S.counts.tycoon))
                if opensBreakArea(entry.button) then
                    UI.toast("NEW BREAKABLE ZONE", (entry.button.Display or entry.button.Id) .. " - farm moved there", THEME.good)
                    local h = UI.handles and UI.handles.tycoonfarm
                    if h then h.set(true, true) end
                    Tycoon.retarget = true
                end
                task.wait(0.3)
            else
                setStatus("tycoon", ("%s refused: %s"):format(entry.button.Id, tostring(reason or success)))
                break
            end
        end
        if boughtNow == 0 then
            local nextUp = list[1]
            if nextUp then
                setStatus("tycoon", ("Next: %s  ·  %s / %s coins"):format(nextUp.button.Display or nextUp.button.Id, short(coins), short(nextUp.price)))
            else
                setStatus("tycoon", "Everything in the tycoon is bought")
            end
        end
    end)

    loop("tycoonupgrades", 1, function()
        local plot, _, m = Tycoon.plot()
        if not plot then return setStatus("tycoonupgrades", "Join the Pumpkin Tycoon event to use this") end
        local okT, tokens = pcall(m.UpgradesClient.Tokens)
        tokens = okT and tonumber(tokens) or 0
        local best
        for _, id in ipairs(UPGRADE_ORDER) do
            if m.Upgrades.ROWS[id] and not best then
                local tier = m.UpgradesClient.Tier(id) or 0
                local okMax, max = pcall(m.UpUtil.MaxTier, id)
                if okMax and tier < max then
                    local okC, cost = pcall(m.UpgradesClient.Cost, id, tier + 1)
                    if okC and type(cost) == "number" and cost <= tokens then best = { id = id, cost = cost, tier = tier + 1 } end
                end
            end
        end
        if not best then return setStatus("tycoonupgrades", ("Saving tokens  ·  %d now"):format(tokens)) end
        local ok, success, reason = pcall(function() return plot:Invoke(m.UpgradesClient.VERB_BUY, best.id) end)
        if ok and success == true then
            S.counts.tycoon += 1
            setStatus("tycoonupgrades", ("%s -> tier %d for %d tokens"):format(best.id, best.tier, best.cost))
        else
            setStatus("tycoonupgrades", ("%s refused: %s"):format(best.id, tostring(reason or success)))
        end
    end)

    -- zone farm: stand in the best zone, pets on every breakable there    local running = false
    function Tycoon.startFarm()
        if running then return end
        running = true
        task.spawn(function()
            env.__PS99HUB_FARM_ON = true
            local section, slab, zoneName, lastTp, spot, eggName = nil, nil, nil, 0, nil, nil
            local hits, prefix = 0, nil
            local lootConn
            local lootFolder = G.THINGS:FindFirstChild("Lootbags")
            if lootFolder then
                lootConn = lootFolder.ChildAdded:Connect(function(item)
                    task.wait()
                    pcall(G.Network.Fire, "Lootbags_Claim", { item.Name })
                end)
            end
            while S.on.tycoonfarm and alive() do
                local plot = Tycoon.plot()
                if not plot then
                    setStatus("tycoonfarm", "Only works inside the Pumpkin Tycoon")
                    task.wait(1)
                else
                    if not prefix or Tycoon.retarget then
                        Tycoon.retarget = false
                        local idx
                        idx, section, slab, zoneName, eggName = Tycoon.bestZone()
                        prefix = section and (section .. "_Zone") or nil
                        spot = slab and Tycoon.standSpot(slab, eggName) or nil
                        Tycoon.spot, Tycoon.eggName = spot, eggName
                        lastTp = 0
                    end
                    local root = hrp()
                    if spot and root and not moving then
                        local off = root.Position - spot.Position
                        if Vector3.new(off.X, 0, off.Z).Magnitude > 6 and os.clock() - lastTp > 3 then
                            root.AssemblyLinearVelocity = Vector3.zero
                            root.CFrame = spot
                            lastTp = os.clock()
                        end
                    end
                    local valid = {}
                    if prefix then
                        for _, b in ipairs(G.THINGS.Breakables:GetChildren()) do
                            local area = b:GetAttribute("AreaID")
                            if area and area:sub(1, #prefix) == prefix then valid[#valid + 1] = b.Name end
                        end
                    end
                    local pets = {}
                    for id in pairs(G.PlayerPet.GetAll()) do pets[#pets + 1] = tostring(id) end
                    if #valid > 0 and #pets > 0 then
                        local map = {}
                        for i, pet in ipairs(pets) do
                            local target = valid[(i - 1) % #valid + 1]
                            map[target] = map[target] or {}
                            table.insert(map[target], pet)
                        end
                        pcall(G.Network.UnreliableFire, "Breakables_PlayerDealDamage", valid[math.random(#valid)])
                        pcall(G.Network.Fire, "Breakables_JoinPetBulk", map)
                        hits += 1
                        if hits % 20 == 0 then
                            setStatus("tycoonfarm", ("Farming %s  ·  %d breakables  ·  %d pets"):format(tostring(zoneName or section), #valid, #pets))
                        end
                        task.wait(0.1)
                    else
                        setStatus("tycoonfarm", ("Waiting for breakables in %s"):format(tostring(zoneName or section or "-")))
                        task.wait(0.5)
                    end
                end
            end
            if lootConn then lootConn:Disconnect() end
            env.__PS99HUB_FARM_ON = S.on.farm == true
            running = false
        end)
    end
end
-- EQUIP BEST / ANTI AFK ----------------------------------------------
loop("equipbest", 30, function()
    if G.PetCmds and pcall(G.PetCmds.EquipBest) then setStatus("equipbest", "Equipped your best pets  ·  " .. os.date("%H:%M")) end
end)
do
    local VU = game:GetService("VirtualUser")
    LocalPlayer.Idled:Connect(function()
        if S.on.antiafk then pcall(function() VU:CaptureController() VU:ClickButton2(Vector2.new()) end) end
    end)
end

-- REWARDS ------------------------------------------------------------
loop("freegifts", 20, function()
    local sv = save()
    local claimed = 0
    for _, g in pairs(G.Directory.FreeGifts) do
        if not table.find(sv.FreeGiftsRedeemed, g.Id) and g.WaitTime <= sv.FreeGiftsTime then
            if invoke("Redeem Free Gift", g.Id) then claimed += 1 S.counts.gifts += 1 end
            task.wait(0.4)
        end
    end
    local left = #G.Directory.FreeGifts - #sv.FreeGiftsRedeemed
    setStatus("freegifts", ("%d claimed this session  ·  %d left today"):format(S.counts.gifts, math.max(0, left)))
end)
loop("rankrewards", 60, function()
    fire("Ranks_ClaimAll")
    setStatus("rankrewards", "Rank rewards claimed  ·  rank " .. tostring(save().Rank))
end)
loop("loginstreak", 300, function()
    local ok, msg = invoke("Login Streaks: Claim")
    setStatus("loginstreak", ok and "Claimed today's streak" or ("Waiting  ·  " .. tostring(msg or "already claimed")))
end)
loop("mailbox", 120, function()
    local ok, msg = invoke("Mailbox: Claim All")
    setStatus("mailbox", ok and "Claimed all mail" or tostring(msg or "No mail"))
end)
loop("foreverpack", 60, function()
    if not G.ForeverPackCmds then return end
    local got = 0
    for _ = 1, 5 do
        local st = G.ForeverPackCmds.GetState("Default")
        local slot = st and st.Slots[st.Slot + 1]
        if not slot or (slot.Price and not slot.Free and not slot.Credit) then break end
        if not invoke("ForeverPacks: Claim Free", "Default") then break end
        got += 1
        task.wait(1.5)
    end
    setStatus("foreverpack", got > 0 and ("Claimed %d free pack slot%s"):format(got, got == 1 and "" or "s") or "Next slot is paid - waiting")
end)
loop("relics", 45, function()
    local list
    for _ = 1, 3 do list = select(1, invoke("Relics_Request")) if type(list) == "table" then break end task.wait(1) end
    if type(list) ~= "table" then return setStatus("relics", "Relic list unavailable, retrying") end
    local owned, total, found = save().ShinyRelics, 0, 0
    for _, r in pairs(list) do
        total += 1
        if not table.find(owned, r.Id) then
            if invoke("Relic_Found", r.Id) then found += 1 S.counts.relics += 1 end
            task.wait(0.25)
        end
    end
    setStatus("relics", ("%d / %d relics found  ·  +%d this session"):format(#save().ShinyRelics, total, S.counts.relics))
end)
do
    local cache
    loop("presents", 30, function()
        if not cache then
            local ok, list = pcall(G.Network.Invoke, "Hidden Presents: Request Cache")
            if ok and type(list) == "table" then cache = list end
        end
        if type(cache) ~= "table" then return setStatus("presents", "Waiting for the present list") end
        local left = 0
        for key, p in pairs(cache) do
            if p and p.ID then
                local ok = invoke("Hidden Presents: Found", p.ID)
                if ok then S.counts.presents += 1 end
                cache[key] = nil
                task.wait(0.3)
            end
        end
        for _ in pairs(cache) do left += 1 end
        setStatus("presents", ("%d presents found this session"):format(S.counts.presents))
    end)
end
loop("turkeys", 10, function()
    local found = 0
    for _, model in ipairs(CollectionService:GetTagged("Turkey")) do
        local id = model:GetAttribute("Id")
        id = (typeof(id) == "string" and #id > 0) and id or model.Name
        if not (save().TurkeysFound or {})[id] then
            local ok = invoke("HiddenTurkey_Found", id)
            if ok then found += 1 pcall(function() model:Destroy() end) end
        end
    end
    local total = 0 for _ in pairs(save().TurkeysFound or {}) do total += 1 end
    setStatus("turkeys", ("%d turkeys found  ·  they appear as you explore"):format(total))
end)
loop("daycare", 60, function()
    if G.DaycareCmds and pcall(G.DaycareCmds.Claim) then setStatus("daycare", "Collected finished daycare pets  ·  " .. os.date("%H:%M")) end
end)

-- timed reward machines in this world: hop on, claim, hop back
loop("machines", 60, function()
    if inInstance() then return setStatus("machines", "Leave the instance to reach the machines") end
    local map = workspace:FindFirstChild("Map")
    if not map then return end
    local sv, now = save(), workspace:GetServerTimeNow()
    local ready = {}
    for _, d in ipairs(map:GetDescendants()) do
        if d:IsA("Model") and d.Parent and d.Parent.Name == "Machines" and G.Directory.TimedRewards[d.Name] then
            local def, ts = G.Directory.TimedRewards[d.Name], sv.TimedRewardTimestamps[d.Name]
            if (not ts or def.Cooldown < now - ts) and not (S.skipMachine or {})[d.Name] then ready[#ready + 1] = d end
        end
    end
    if #ready == 0 then return setStatus("machines", ("Nothing ready  ·  %d claimed this session"):format(S.counts.machines)) end
    withTeleport(function(root)
        for _, m in ipairs(ready) do
            if not S.on.machines then break end
            local pad = m:FindFirstChild("Pad") or m.PrimaryPart or m:FindFirstChildWhichIsA("BasePart", true)
            if pad then
                root.CFrame = CFrame.new(pad.Position + Vector3.new(0, 4, 0))
                task.wait(0.6)
                local ok, msg = invoke("DailyRewards_Redeem", m.Name)
                if ok then
                    S.counts.machines += 1
                    UI.toast("MACHINE CLAIMED", m.Name, THEME.gold)
                elseif tostring(msg):find("own") or msg == false or msg == nil then
                    -- needs VIP, the group or a locked zone: stop retrying it
                    S.skipMachine = S.skipMachine or {}
                    S.skipMachine[m.Name] = true
                end
                task.wait(0.3)
            end
        end
    end)
    setStatus("machines", ("%d claimed this session"):format(S.counts.machines))
end)

-- balloon gifts: slingshot from below, then stand on the gift
loop("balloons", 20, function()
    if inInstance() then return setStatus("balloons", "Balloons float over the main world") end
    local folder = G.THINGS:FindFirstChild("BalloonGifts")
    local targets = {}
    for _, m in ipairs(folder and folder:GetChildren() or {}) do
        local b = m:FindFirstChild("Balloon")
        if b and b:GetAttribute("BalloonId") and b.Transparency < 1 then targets[#targets + 1] = m end
    end
    if #targets == 0 then return setStatus("balloons", ("No balloons up  ·  %d popped this session"):format(S.counts.balloons)) end
    task.spawn(function() invoke("Slingshot_Toggle") end)
    task.wait(1)
    withTeleport(function(root)
        for _, m in ipairs(targets) do
            if not S.on.balloons then break end
            local bal, gift = m:FindFirstChild("Balloon"), m:FindFirstChild("Giftbox")
            if bal and bal.Parent then
                root.CFrame = CFrame.new(bal.Position + Vector3.new(6, -12, 0))
                root.Anchored = true
                task.wait(0.8)
                local origin = root.Position + Vector3.new(0, 2, 0)
                local d = bal.Position - origin
                task.spawn(function() invoke("Slingshot_FireProjectile", origin, math.atan2(d.Z, d.X), math.atan2(d.Y, Vector3.new(d.X, 0, d.Z).Magnitude), 120) end)
                task.wait(0.4)
                fire("BalloonGifts_BalloonHit", bal:GetAttribute("BalloonId"))
                root.Anchored = false
                local t0 = os.clock()
                while gift and gift.Parent and os.clock() - t0 < 10 do
                    root.CFrame = CFrame.new(gift.Position + Vector3.new(0, 2, 0))
                    pcall(firetouchinterest, root, gift, 0)
                    pcall(firetouchinterest, root, gift, 1)
                    task.wait(0.25)
                end
                if not (gift and gift.Parent) then
                    S.counts.balloons += 1
                    UI.toast("BALLOON POPPED", "Gift collected", THEME.accent)
                end
            end
        end
    end)
    task.spawn(function() invoke("Slingshot_Toggle") end)
    setStatus("balloons", ("%d balloons popped this session"):format(S.counts.balloons))
end)

-- ITEMS ----------------------------------------------------------------
loop("fruits", 15, function()
    if not G.FruitCmds then return end
    local eaten = 0
    for uid, item in pairs(save().Inventory.Fruit or {}) do
        local okM, max = pcall(G.FruitCmds.GetMaxConsume, item.id)
        local amount = (okM and type(max) == "number") and math.min(max, item._am or 1) or 0
        if amount > 0 then
            pcall(G.FruitCmds.Consume, uid, amount)
            eaten += amount
            task.wait(0.3)
        end
    end
    S.counts.fruits += eaten
    setStatus("fruits", eaten > 0 and ("Ate %d fruit  ·  %d this session"):format(eaten, S.counts.fruits) or "Fruit boosts are full")
end)
loop("potions", 20, function()
    if not G.PotionCmds then return end
    local okA, active = pcall(G.PotionCmds.GetActivePotions)
    active = okA and type(active) == "table" and active or {}
    local best = {}
    for uid, item in pairs(save().Inventory.Potion or {}) do
        local cur = best[item.id]
        if not cur or (item.tn or 1) > (cur.tn or 1) then best[item.id] = { uid = uid, tn = item.tn or 1 } end
    end
    local used = 0
    for id, pick in pairs(best) do
        if not active[id] then
            pcall(G.PotionCmds.Consume, pick.uid, 1)
            used += 1
            task.wait(0.4)
        end
    end
    S.counts.potions += used
    setStatus("potions", used > 0 and ("Drank %d potion%s"):format(used, used == 1 and "" or "s") or "Every potion type is already active")
end)
loop("lootboxes", 8, function()
    if not G.LootboxCmds then return end
    for _, item in pairs(inventoryItems()) do
        local id = itemId(item)
        local okD, dir = pcall(function() return item:Directory() end)
        if id and okD and type(dir) == "table" and G.Directory.Lootboxes[id] and not id:find("Locked") and not dir.IsCardPack then
            local amt = math.min(item:GetAmount(), 5)
            if amt > 0 and pcall(G.LootboxCmds.Open, item, amt) then
                S.counts.lootboxes += amt
                setStatus("lootboxes", ("Opened %d %s  ·  %d this session"):format(amt, id, S.counts.lootboxes))
                return
            end
        end
    end
    setStatus("lootboxes", ("Nothing left to open  ·  %d this session"):format(S.counts.lootboxes))
end)
do
    local BAGS = { "Gift Bag", "Large Gift Bag", "Seed Bag", "Charm Stone" }
    loop("giftbags", 10, function()
        local opened = 0
        for _, item in pairs(inventoryItems()) do
            local id = itemId(item)
            if id and table.find(BAGS, id) then
                local ok = invoke("GiftBag_Open", id, 1)
                if ok then opened += 1 end
                task.wait(0.4)
            elseif id and id:find("Bundle$") then
                local ok = invoke("GiftBag_Open", id, 1)
                if ok then opened += 1 end
                task.wait(0.4)
            end
        end
        setStatus("giftbags", opened > 0 and ("Opened %d bag%s"):format(opened, opened == 1 and "" or "s") or "No bags or bundles left")
    end)
end
loop("toys", 30, function()
    local used = {}
    for _, name in ipairs({ "ToyBall_Consume", "ToyBone_Consume", "SqueakyToy_Consume" }) do
        local ok = invoke(name)
        if ok then used[#used + 1] = name:match("^(%a+)") end
        task.wait(0.4)
    end
    setStatus("toys", #used > 0 and ("Used " .. table.concat(used, ", ")) or "Pet toys still active")
end)
loop("keys", 30, function()
    local made = 0
    for _, pair in ipairs({ { "Crystal Key", "CrystalKey_Combine" }, { "Secret Key", "SecretKey_Combine" }, { "Tech Key", "TechKey_Combine" },
        { "Void Key", "VoidKey_Combine" }, { "Fantasy Key", "FantasyKey_Combine" } }) do
        local lower, upper = 0, 0
        for _, item in pairs(inventoryItems()) do
            local id = itemId(item)
            if id == pair[1] .. " Lower Half" then lower = item:GetAmount() end
            if id == pair[1] .. " Upper Half" then upper = item:GetAmount() end
        end
        local n = math.min(lower, upper)
        if n > 0 and invoke(pair[2], n) then made += n S.counts.keys += n end
        task.wait(0.3)
    end
    setStatus("keys", made > 0 and ("Combined %d key%s"):format(made, made == 1 and "" or "s") or "No matching key halves")
end)

-- zone boosters: only inside a breakable zone in the main world
local function zoneReady(key)
    if inInstance() then setStatus(key, "Use these in a main-world zone") return false end
    local okZ, zone = pcall(function() return G.MapCmds.GetCurrentZone() end)
    if not (okZ and zone) then setStatus(key, "Stand inside a zone") return false end
    return zone
end
loop("flags", 30, function()
    local zone = zoneReady("flags")
    if not zone or not G.FlexibleFlagCmds then return end
    local wanted = Settings.values.flagList or { "Coins Flag", "Diamonds Flag", "Magnet Flag", "Hasty Flag", "Fortune Flag", "Rainbow Flag", "Shiny Flag", "Strength Flag" }
    local placed = 0
    for _, item in pairs(inventoryItems()) do
        local id = itemId(item)
        if id and table.find(wanted, id) then
            local okA, has = pcall(G.FlexibleFlagCmds.GetActiveFlagByKey, id)
            if not (okA and has) then
                local okC, r = pcall(G.FlexibleFlagCmds.Consume, id, item:GetUID(), 1)
                if okC and r then placed += 1 end
                task.wait(0.4)
            end
        end
    end
    setStatus("flags", placed > 0 and ("Placed %d flag%s in %s"):format(placed, placed == 1 and "" or "s", tostring(zone)) or ("Flags up in " .. tostring(zone)))
end)
loop("sprinklers", 60, function()
    local zone = zoneReady("sprinklers")
    if not zone or not G.SprinklerCmds then return end
    for _, item in pairs(inventoryItems()) do
        if itemId(item) == "Breakable Sprinkler" then
            local okA, has = pcall(G.SprinklerCmds.PlayerHasActiveSprinkler, LocalPlayer, "Breakable Sprinkler")
            if not (okA and has) then
                local ok, r = pcall(G.SprinklerCmds.Consume, "Breakable Sprinkler", item:GetUID(), 1)
                setStatus("sprinklers", (ok and r) and ("Sprinkler placed in " .. tostring(zone)) or "Sprinkler already up")
            end
        end
    end
end)
loop("jars", 25, function()
    local zone = zoneReady("jars")
    if not zone then return end
    local used = {}
    for _, item in pairs(inventoryItems()) do
        local id = itemId(item)
        if id == "Basic Coin Jar" or id == "Giant Coin Jar" or id == "Magic Coin Jar" then
            if invoke("CoinJar_Spawn", item:GetUID()) then used[#used + 1] = id end
            task.wait(0.5)
        elseif id == "Comet" then
            if invoke("Comet_Spawn", item:GetUID()) then used[#used + 1] = id end
            task.wait(0.5)
        end
    end
    setStatus("jars", #used > 0 and ("Spawned " .. table.concat(used, ", ")) or "Coin jars and comets on cooldown")
end)
loop("tnt", 20, function()
    if not zoneReady("tnt") then return end
    local a = invoke("TNT_Consume")
    task.wait(0.5)
    local b = invoke("TNT_Crate_Consume")
    setStatus("tnt", (a or b) and "Boom" or "TNT on cooldown")
end)

-- PETS -----------------------------------------------------------------
local function isSpecial(id)
    local ok, dir = pcall(function() return G.Directory.Pets[id] end)
    return ok and type(dir) == "table" and (dir.huge or dir.titanic or dir.gargantuan or dir.exclusiveLevel) and true or false
end
loop("golden", 10, function()
    local made = 0
    for uid, pet in pairs(save().Inventory.Pet or {}) do
        if not pet.pt and not pet.sh and (pet._am or 1) >= 10 and not isSpecial(pet.id) and not pet._lk then
            local batches = math.floor((pet._am or 1) / 10)
            local ok = invoke("GoldMachine_Activate", uid, batches)
            if ok then made += batches S.counts.golden += batches end
            task.wait(0.5)
        end
    end
    setStatus("golden", ("%d golden made this session"):format(S.counts.golden))
end)
loop("rainbow", 10, function()
    for uid, pet in pairs(save().Inventory.Pet or {}) do
        if pet.pt == 1 and not pet.sh and (pet._am or 1) >= 10 and not isSpecial(pet.id) and not pet._lk then
            local batches = math.floor((pet._am or 1) / 10)
            local ok = invoke("RainbowMachine_Activate", uid, batches)
            if ok then S.counts.rainbow += batches end
            task.wait(0.5)
        end
    end
    setStatus("rainbow", ("%d rainbow made this session"):format(S.counts.rainbow))
end)
-- PROGRESS -------------------------------------------------------------
loop("zones", 5, function()
    if inInstance() or not G.ZoneCmds then return setStatus("zones", "Zones are bought in the main world") end
    local okN, nextZone = pcall(G.ZoneCmds.GetNextZone)
    if not okN or not nextZone then return setStatus("zones", "Every zone in this world is open") end
    local name = type(nextZone) == "table" and (nextZone._id or nextZone.ZoneName) or nextZone
    local ok, msg = invoke("Zones_RequestPurchase", name)
    if ok then
        S.counts.zones += 1
        UI.toast("ZONE UNLOCKED", tostring(name), THEME.good)
        setStatus("zones", "Bought " .. tostring(name))
    else
        setStatus("zones", ("Next: %s  ·  %s"):format(tostring(name), tostring(msg or "saving up")))
    end
end)
loop("rebirth", 30, function()
    if not G.RebirthCmds then return end
    local okN, nxt = pcall(G.RebirthCmds.GetNextRebirth)
    if not okN or not nxt then return setStatus("rebirth", "No rebirth available yet") end
    local id = type(nxt) == "table" and (nxt._id or nxt.Id or nxt.id) or nxt
    local ok, msg = pcall(G.RebirthCmds.Rebirth, id)
    setStatus("rebirth", ok and ("Rebirth requested: " .. tostring(id)) or tostring(msg))
end)

-- EGG CHANCES ------------------------------------------------------------
-- Uses the game's own GetProbabilityMap, so every number already includes
-- your luck from potions, enchants, gamepasses and event upgrades.
local Chances = { eggId = nil, map = {}, luck = 0, pinned = nil }
do
    local function petInfo(id)
        local ok, d = pcall(function() return G.Directory.Pets[id] end)
        return ok and d or nil
    end
    Chances.petInfo = petInfo
    function Chances.eggsInRange()
        local list, root = {}, hrp()
        if not root then return list end
        pcall(function()
            for _, e in pairs(G.CustomEggsCmds.All()) do
                local okH, h = pcall(function() return e:IsHatchable() end)
                if okH and h and (e._position - root.Position).Magnitude < 160 then list[#list + 1] = e._id end
            end
        end)
        local folder = G.THINGS:FindFirstChild("Eggs")
        for _, m in ipairs(folder and folder:GetChildren() or {}) do
            local okP, pos = pcall(function() return m:GetPivot().Position end)
            local okD, dir = pcall(function() return G.Directory.Eggs[m.Name] end)
            if okP and okD and dir and (pos - root.Position).Magnitude < 160 and not table.find(list, m.Name) then list[#list + 1] = m.Name end
        end
        return list
    end
    function Chances.currentEgg()
        if Chances.pinned then return Chances.pinned end
        if S.on.hatch and S.target and S.target ~= "-" then return S.target end
        local egg = F.nearestEgg and F.nearestEgg()
        return egg and egg.id or nil
    end
    function Chances.refresh()
        local id = Chances.currentEgg()
        Chances.eggId = id
        if not id then Chances.map, Chances.rows = {}, {} return end
        local okM, map = pcall(G.EggCmds.GetProbabilityMap, id)
        local okL, luck = pcall(G.EggCmds.ComputeLuckBoost, id)
        Chances.map = okM and type(map) == "table" and map or {}
        Chances.luck = okL and tonumber(luck) or 0
        local rows = {}
        for pet, p in pairs(Chances.map) do
            local d = petInfo(pet)
            rows[#rows + 1] = { id = pet, p = p, huge = d and d.huge, titanic = d and (d.titanic or d.gargantuan), thumb = d and d.thumbnail }
        end
        table.sort(rows, function(a, b) return a.p > b.p end)
        Chances.rows = rows
        local okD, dir = pcall(function() return G.Directory.Eggs[id] end)
        Chances.dir = okD and dir or nil
    end
    function Chances.perHatch()
        if S.perHatch and S.perHatch > 0 then return S.perHatch end
        local ok, n = pcall(function() return G.EggCmds.GetMaxHatch(Chances.dir) end)
        return ok and tonumber(n) or 1
    end
end

-- HATCH TRACKER / HUGE ALERTS -------------------------------------------
-- Watches the pet inventory. Only huges, titanics and gargantuans raise an
-- alert (toast + log + Discord webhook if you set one up).
local Tracker = { log = {}, seen = nil, hatched = {}, huges = 0, rares = 0 }

-- DISCORD WEBHOOK ----------------------------------------------------------
local Webhook = {}
do
    local httpRequest = (syn and syn.request) or (http and http.request) or http_request or request or (fluxus and fluxus.request)
    function Webhook.url()
        local u = Settings.values.webhookUrl
        if type(u) ~= "string" then return nil end
        u = u:gsub("^%s+", ""):gsub("%s+$", "")
        if u:match("^https://discord%.com/api/webhooks/") or u:match("^https://discordapp%.com/api/webhooks/")
            or u:match("^https://ptb%.discord%.com/api/webhooks/") or u:match("^https://canary%.discord%.com/api/webhooks/") then
            return u
        end
        return nil
    end
    -- the pet picture: ask Roblox for a real image URL for the thumbnail id
    local function imageUrl(assetId)
        local id = tostring(assetId or ""):match("%d+")
        if not id or not httpRequest then return nil end
        local ok, res = pcall(httpRequest, { Url = ("https://thumbnails.roblox.com/v1/assets?assetIds=%s&size=420x420&format=Png"):format(id), Method = "GET" })
        if not ok or type(res) ~= "table" or not res.Body then return nil end
        local okJ, data = pcall(function() return HttpService:JSONDecode(res.Body) end)
        local entry = okJ and type(data) == "table" and type(data.data) == "table" and data.data[1]
        return entry and entry.imageUrl or nil
    end
    function Webhook.send(info)
        local url = Webhook.url()
        if not url then return false, "no webhook set" end
        if not httpRequest then return false, "this executor has no http request function" end
        local colour = info.tag == "TITANIC" and 0xFF78E6 or (info.tag == "GARGANTUAN" and 0xFF6E6E or 0xFFD33D)
        local fields = {
            { name = "Pet", value = info.name, inline = true },
            { name = "Amount", value = tostring(info.amount or 1), inline = true },
        }
        if info.egg then fields[#fields + 1] = { name = "Egg", value = info.egg, inline = true } end
        if info.chance then fields[#fields + 1] = { name = "Chance", value = "1 in " .. commas(1 / info.chance), inline = true } end
        local okH, lifetime = pcall(function() return save().EggsHatched end)
        if okH and lifetime then fields[#fields + 1] = { name = "Eggs hatched", value = commas(lifetime), inline = true } end
        fields[#fields + 1] = { name = "Huges this session", value = tostring(Tracker.huges), inline = true }
        local embed = {
            title = info.tag .. " HATCHED!",
            description = ("**%s** just got **%s**"):format(LocalPlayer.Name, info.name),
            color = colour,
            fields = fields,
            footer = { text = "PS99 Hub" },
            timestamp = DateTime.now():ToIsoDate(),
        }
        local img = imageUrl(info.thumb)
        if img then embed.thumbnail = { url = img } end
        local body = { username = "PS99 Hub", embeds = { embed } }
        -- only ever pings the one Discord user ID you saved, never @everyone / @here
        local pingId = tostring(Settings.values.webhookPingId or ""):match("^%s*(%d+)%s*$")
        if S.on.webhookping and pingId and #pingId >= 15 then
            body.content = ("<@%s>"):format(pingId)
            body.allowed_mentions = { users = { pingId } }
        else
            body.allowed_mentions = { parse = {} }
        end
        local ok, res = pcall(httpRequest, { Url = url, Method = "POST", Headers = { ["Content-Type"] = "application/json" }, Body = HttpService:JSONEncode(body) })
        if not ok then return false, tostring(res) end
        local code = type(res) == "table" and tonumber(res.StatusCode) or 0
        if code >= 200 and code < 300 then return true end
        return false, ("Discord answered %s"):format(tostring(code))
    end
end
env.__PS99HUB_WEBHOOK = Webhook
do
    local function snapshot()
        local counts = {}
        local ok, inv = pcall(function() return save().Inventory.Pet end)
        for _, pet in pairs(ok and inv or {}) do
            if type(pet) ~= "table" or type(pet.id) ~= "string" then continue end
            local key = pet.id .. "|" .. tostring(pet.pt or 0) .. "|" .. tostring(pet.sh or false)
            counts[key] = (counts[key] or 0) + (pet._am or 1)
        end
        return counts
    end
    local function push(text, colour)
        table.insert(Tracker.log, 1, { text = text, colour = colour, at = os.date("%H:%M:%S") })
        while #Tracker.log > 8 do table.remove(Tracker.log) end
    end
    Tracker.push = push
    loop("hatchalerts", 1, function()
        local now = snapshot()
        if not Tracker.seen then Tracker.seen = now return end

        for key, amount in pairs(now) do
            local gained = amount - (Tracker.seen[key] or 0)
            if gained > 0 then
                local id, pt, sh = key:match("^(.-)|(%d+)|(%a+)$")
                Tracker.hatched[id] = (Tracker.hatched[id] or 0) + gained
                local d = Chances.petInfo(id)
                local variant = (pt == "2" and "Rainbow " or pt == "1" and "Golden " or "") .. (sh == "true" and "Shiny " or "")
                local p = Chances.map[id]
                if d and (d.huge or d.titanic or d.gargantuan) then
                    Tracker.huges += gained
                    local tag = d.gargantuan and "GARGANTUAN" or (d.titanic and "TITANIC" or "HUGE")
                    push(("%s  %s%s x%d"):format(tag, variant, id, gained), THEME.gold)
                    UI.toast(tag .. " HATCHED!", variant .. id, THEME.gold)
                    if S.on.webhook and Webhook.url() then
                        local info = { tag = tag, name = variant .. id, amount = gained, egg = Chances.eggId, chance = p,
                            thumb = (pt == "1" and d.goldenThumbnail) or d.thumbnail }
                        task.spawn(function()
                            local ok, err = Webhook.send(info)
                            setStatus("webhook", ok and ("Sent %s to Discord  ·  %s"):format(info.name, os.date("%H:%M")) or ("Webhook failed: " .. tostring(err)))
                        end)
                    end
                end
            end
        end
        Tracker.seen = now
        setStatus("hatchalerts", ("%d huge%s this session"):format(Tracker.huges, Tracker.huges == 1 and "" or "s"))
    end)
end

-- SLOTS (equip + egg) ----------------------------------------------------

local function slotBuy(remote, arg, machineName)
    local ok, msg = invoke(remote, arg)
    if ok then return true end
    -- some machines want you standing at them: hop over in this world and back
    if tostring(msg):lower():find("far") and not inInstance() then
        local pad
        local map = workspace:FindFirstChild("Map")
        for _, d in ipairs(map and map:GetDescendants() or {}) do
            if d.Name == machineName and d:IsA("Model") then pad = d:FindFirstChild("Pad") or d:FindFirstChildWhichIsA("BasePart", true) break end
        end
        if pad then
            local result
            withTeleport(function(root)
                root.CFrame = CFrame.new(pad.Position + Vector3.new(0, 4, 0))
                task.wait(0.6)
                result = { invoke(remote, arg) }
            end)
            if result and result[1] then return true end
            msg = result and result[2] or msg
        end
    end
    return false, msg
end
loop("equipslots", 15, function()
    local sv = save()
    local nextSlot = (sv.PetSlotsPurchased or 0) + 1
    local okMax, max = pcall(function() return require(RS.Library.Util.RanksUtil).GetMaxEquipSlots() end)
    if okMax and type(max) == "number" and nextSlot > max then return setStatus("equipslots", ("All %d slots for your rank are bought"):format(max)) end
    local okP, price = pcall(function() return require(RS.Library.Balancing).CalcPetSlotPrice(nextSlot) end)
    price = okP and tonumber(price) or math.huge
    local reserve = (tonumber(Settings.values.slotReserve) or 2) * 1e6
    if diamonds() - price < reserve then
        return setStatus("equipslots", ("Slot %d costs %s  ·  keeping %s diamonds"):format(nextSlot, short(price), short(reserve)))
    end
    local ok, msg = slotBuy("EquipSlotsMachine_RequestPurchase", nextSlot, "EquipSlotsMachine")
    if ok then UI.toast("EQUIP SLOT BOUGHT", ("Slot %d"):format(nextSlot), THEME.good) end
    setStatus("equipslots", ok and ("Bought equip slot %d for %s"):format(nextSlot, short(price)) or ("Slot %d: %s"):format(nextSlot, tostring(msg)))
end)
loop("eggslots", 15, function()
    local sv = save()
    local have = sv.EggSlotsPurchased or 0
    local okB, bundles = pcall(function() return require(RS.Library.Util.EggSlotBundles).All() end)
    if not okB then return setStatus("eggslots", "Egg slot list unavailable") end
    local nextB
    for _, b in pairs(bundles) do if b.Start == have + 1 then nextB = b end end
    if not nextB then return setStatus("eggslots", "Every egg slot is bought") end
    local cost = 0
    for m = nextB.Start, nextB.End do cost += require(RS.Library.Balancing).CalcEggSlotPrice(m) end
    local reserve = (tonumber(Settings.values.slotReserve) or 2) * 1e6
    if diamonds() - cost < reserve then
        return setStatus("eggslots", ("Slots %d-%d cost %s  ·  keeping %s diamonds"):format(nextB.Start, nextB.End, short(cost), short(reserve)))
    end
    local ok, msg = slotBuy("EggHatchSlotsMachine_RequestPurchase", nextB.End, "EggHatchSlotsMachine")
    if ok then UI.toast("EGG SLOTS BOUGHT", ("Now hatching %d at once"):format(nextB.End), THEME.good) end
    setStatus("eggslots", ok and ("Bought egg slots %d-%d"):format(nextB.Start, nextB.End) or ("Slots %d-%d: %s"):format(nextB.Start, nextB.End, tostring(msg)))
end)

-- VENDING MACHINES (this world only) ------------------------------------
loop("vending", 60, function()
    if inInstance() then return setStatus("vending", "Vending machines are in the main world") end
    local map = workspace:FindFirstChild("Map")
    if not map then return end
    local sv = save()
    local wantDiamond = S.on.vendingdiamonds
    local stops = {}
    for id, dir in pairs(G.Directory.VendingMachines) do
        local stock = sv.VendingStocks[id] or 0
        if stock > 0 and (dir.CurrencyType ~= "Diamonds" or wantDiamond) then
            for _, d in ipairs(map:GetDescendants()) do
                if d.Name == dir.MachineName and d:IsA("Model") then
                    local pad = d:FindFirstChild("Pad") or d:FindFirstChildWhichIsA("BasePart", true)
                    if pad then stops[#stops + 1] = { id = id, pad = pad, stock = stock } end
                    break
                end
            end
        end
    end
    if #stops == 0 then return setStatus("vending", "Nothing in stock nearby  ·  restocks over time") end
    local bought = 0
    withTeleport(function(root)
        for _, s in ipairs(stops) do
            if not S.on.vending then break end
            root.CFrame = CFrame.new(s.pad.Position + Vector3.new(0, 4, 0))
            task.wait(0.6)
            local ok = invoke("VendingMachines_Purchase", s.id, math.min(3, s.stock))
            if not ok then ok = invoke("VendingMachines_Purchase", s.id, 1) end
            if ok then bought += 1 end
            task.wait(0.3)
        end
    end)
    setStatus("vending", ("Bought from %d machine%s  ·  %s"):format(bought, bought == 1 and "" or "s", os.date("%H:%M")))
end)

-- TYCOON WILD PETS ---------------------------------------------------------
-- Wild pets roam the island with a catch chance on each. The server only
-- accepts a throw from near the pet's spawn spot (phys.At), so each catch
-- hops over under the teleport lock (the zone farm waits) and comes back.
local function itemCount(id)
    local n = 0
    for _, item in pairs(inventoryItems()) do
        if itemId(item) == id then n += (item:GetAmount() or 0) end
    end
    return n
end
loop("wildcatch", 3, function()
    local plot, _, m = Tycoon.plot()
    if not plot then return setStatus("wildcatch", "Only works inside the Pumpkin Tycoon") end
    local okW, Wild = pcall(m.Cmds.Feature, "Wild")
    if not (okW and Wild) then return setStatus("wildcatch", "Wild pets unlock with part 2 of the tycoon") end
    local nets, ultras = itemCount("Pet Net"), itemCount("Ultra Pet Net")
    if nets + ultras == 0 then return setStatus("wildcatch", "Out of Pet Nets  ·  turn on Auto Buy Nets") end
    local minChance = (tonumber(Settings.values.wildMin) or 50) / 100
    local best, bestScore
    for slot, phys in pairs(Wild.All() or {}) do
        if type(phys) == "table" and phys.At and not phys.Catching and not phys.AttemptingCatch and not phys.SoldOut then
            local chance = tonumber(phys.CatchChance) or 0
            local entry = type(phys.Entry) == "table" and phys.Entry or {}
            local d = Chances.petInfo(entry.P or "")
            local special = d and (d.huge or d.titanic)
            local useUltra = ultras > 0 and S.on.wildultra and (special or chance < minChance)
            local effective = useUltra and math.min(1, chance * 5) or chance
            if effective >= minChance or special then
                local score = (special and 10 or 0) + effective + (entry.R and 0.5 or 0) + (entry.G and 0.2 or 0) + (entry.S and 1 or 0)
                if not bestScore or score > bestScore then
                    best, bestScore = { slot = slot, phys = phys, net = useUltra and "Ultra Pet Net" or "Pet Net", pet = entry.P, chance = chance }, score
                end
            end
        end
    end
    if not best then return setStatus("wildcatch", ("No wild pet at %d%%+ right now  ·  %d nets"):format(minChance * 100, nets)) end
    if best.net == "Pet Net" and nets == 0 then best.net = "Ultra Pet Net" end
    local result
    withTeleport(function(root)
        root.CFrame = CFrame.new(best.phys.At + Vector3.new(3, 3, 0))
        task.wait(0.8)
        result = { pcall(function() return plot:Invoke(m.Types.NET.CatchWild, best.slot, best.net) end) }
        -- the server can lag a beat behind the hop: one retry from right on top of it
        if result[1] and result[2] ~= true and tostring(result[3]):find("closer") then
            root.CFrame = CFrame.new(best.phys.At + Vector3.new(0, 3, 0))
            task.wait(1)
            result = { pcall(function() return plot:Invoke(m.Types.NET.CatchWild, best.slot, best.net) end) }
        end
        task.wait(0.4)
    end)
    if result and result[1] and result[2] == true then
        local outcome = type(result[4]) == "table" and (result[4].outcome or result[4].Outcome) or nil
        local caught = tostring(outcome):lower() == "caught"
        S.counts.wild = (S.counts.wild or 0) + 1
        S.counts.wildCaught = (S.counts.wildCaught or 0) + (caught and 1 or 0)
        if caught then UI.toast("WILD PET CAUGHT", ("%s  ·  %d%% throw"):format(tostring(best.pet), best.chance * 100), THEME.good) end
        setStatus("wildcatch", ("%s %s (%d%%)  ·  caught %d of %d this session"):format(caught and "Caught" or "Missed", tostring(best.pet), best.chance * 100, S.counts.wildCaught, S.counts.wild))
        task.wait(2.5)
    else
        setStatus("wildcatch", ("%s: %s"):format(tostring(best.pet), tostring(result and (result[3] or result[2]) or "no answer")))
    end
end)

-- EXTRA CLAIMS -------------------------------------------------------------
loop("extraclaims", 120, function()
    local got = {}
    for _, name in ipairs({ "WelcomeBack: Claim", "Exclusive Daycare: Claim", "Transferring_ClaimAll" }) do
        if invoke(name) then got[#got + 1] = name:match("^[^:_]+") end
        task.wait(0.3)
    end
    fire("DiamondParty_Claim")
    setStatus("extraclaims", #got > 0 and ("Claimed " .. table.concat(got, ", ")) or ("Nothing waiting  ·  checked " .. os.date("%H:%M")))
end)

-- SPINNY WHEEL (main world) -------------------------------------------------
loop("spinwheel", 20, function()
    if inInstance() then return setStatus("spinwheel", "The wheel is in the main world spawn") end
    local tickets = itemCount("Spinny Wheel Ticket")
    if tickets == 0 then return setStatus("spinwheel", "No Spinny Wheel Tickets left") end
    local map = workspace:FindFirstChild("Map")
    local pad
    for _, d in ipairs(map and map:GetDescendants() or {}) do
        if d:IsA("Model") and d.Name:find("SpinnyWheel") then pad = d:FindFirstChild("Pad") or d:FindFirstChildWhichIsA("BasePart", true) break end
    end
    local spun, msg = 0, nil
    local function spinSome()
        for _ = 1, math.min(5, tickets) do
            local ok, m2 = invoke("Spinny Wheel: Request Spin", "StarterWheel")
            if not ok then msg = m2 break end
            spun += 1
            task.wait(5.5)
        end
    end
    spinSome()
    if spun == 0 and pad then withTeleport(function(root) root.CFrame = CFrame.new(pad.Position + Vector3.new(0, 4, 0)) task.wait(0.8) spinSome() end) end
    setStatus("spinwheel", spun > 0 and ("Spun %d times  ·  %d tickets left"):format(spun, tickets - spun) or ("Can't spin: " .. tostring(msg)))
end)
-- DAYCARE ENROLL -----------------------------------------------------------
-- Never touches your best pets: every pet type that makes your top team
-- (strongest copies up to your equip limit) or is equipped right now is off
-- limits. From what is left it picks ONE stack big enough to fill every free
-- slot by itself, the biggest stack first, so the slots fill with fodder.
loop("daycareenroll", 30, function()
    if not G.DaycareCmds then return end
    local okM, max = pcall(G.DaycareCmds.GetMaxSlots)
    local okU, used = pcall(G.DaycareCmds.GetUsedSlots)
    if not (okM and okU) then return end
    local free = (max or 0) - (used or 0)
    if free <= 0 then return setStatus("daycareenroll", ("All %d slots busy  ·  claims refill them"):format(max)) end
    local okL, DL = pcall(function() return require(RS.Library.Modules.DaycareLoot) end)
    if not okL then return setStatus("daycareenroll", "Daycare rules unavailable") end

    local stacks = {}
    for _, it in pairs(inventoryItems()) do
        local ok, info = pcall(function()
            if not it:IsA("Pet") then return nil end
            return { item = it, uid = it:GetUID(), id = it:GetId(), amount = it:GetAmount(), power = it:CalculatePower() }
        end)
        if ok and info then stacks[#stacks + 1] = info end
    end
    -- your best team: walk copies strongest first until the equip limit is filled
    local protected = {}
    for _, p in pairs(G.PlayerPet.GetAll()) do if p.id then protected[p.id] = true end end
    table.sort(stacks, function(a, b) return a.power > b.power end)
    local teamSize = tonumber(save().MaxPetsEquipped) or 50
    local counted = 0
    for _, st in ipairs(stacks) do
        if counted >= teamSize then break end
        protected[st.id] = true
        counted += st.amount
    end

    local best
    for _, st in ipairs(stacks) do
        if not protected[st.id] and st.amount >= free then
            local okC, can = pcall(DL.CanEnroll, st.item)
            if okC and can and (not best or st.amount > best.amount or (st.amount == best.amount and st.power < best.power)) then best = st end
        end
    end
    if not best then
        return setStatus("daycareenroll", ("Waiting for a spare stack of %d+ (best pets are never used)"):format(free))
    end
    local ok, a, b = pcall(G.DaycareCmds.Enroll, { [best.uid] = free })
    if ok and a then
        UI.toast("DAYCARE", ("Enrolled %d x %s"):format(free, best.id), THEME.good)
        setStatus("daycareenroll", ("Enrolled %d x %s (stack of %s)"):format(free, best.id, commas(best.amount)))
    else
        setStatus("daycareenroll", "Enroll refused: " .. tostring(b or a))
    end
end)
-- TYCOON HOT COCOA -----------------------------------------------------------
-- Keeps the three cocoa boosts (coins, damage, island luck) topped up. They
-- cost Patch Coins per minute and the stand only sells to you in person.
loop("cocoa", 20, function()
    local plot, _, m = Tycoon.plot()
    if not plot then return setStatus("cocoa", "Only works inside the Pumpkin Tycoon") end
    local okC, CocoaUtil = pcall(function() return require(RS.Library.Util.PumpkinTycoonCocoa) end)
    local okK, Cocoa = pcall(function() return require(RS.Library.Client.PumpkinTycoonCmds.Cocoa) end)
    if not (okC and okK) then return end
    local minutes = tonumber(Settings.values.cocoaMinutes) or 30
    local need = {}
    for _, offer in pairs(CocoaUtil.OFFERS) do
        local okR, left = pcall(Cocoa.Remaining, offer.Id)
        if okR and (tonumber(left) or 0) < 120 then need[#need + 1] = offer end
    end
    if #need == 0 then return setStatus("cocoa", "All three cocoa boosts are running") end
    local stand
    -- your own island only: other players' islands have a stand too
    pcall(function()
        local decor = m.Island.Decor(plot)
        stand = decor and decor:FindFirstChild("PumpkinTycoonCocoaStand_Look", true)
    end)
    if not stand then return setStatus("cocoa", "Build the Hot Cocoa Stand first") end
    local spot = stand:GetPivot().Position
    local bought, reason = {}, nil
    withTeleport(function(root)
        root.CFrame = CFrame.new(spot + Vector3.new(0, 4, 8), spot)
        task.wait(0.8)
        for _, offer in ipairs(need) do
            -- the stand has a short cooldown between sales: space them out, retry once
            for _ = 1, 2 do
                local ok, a, b = pcall(function() return plot:Invoke(CocoaUtil.VERB_BUY, offer.Id, minutes) end)
                if ok and a == true then bought[#bought + 1] = offer.Axis break end
                reason = b or a
                task.wait(1.2)
            end
            task.wait(1.2)
        end
    end)
    if #bought > 0 then
        setStatus("cocoa", ("Bought %d min of %s cocoa"):format(minutes, table.concat(bought, ", ")))
    else
        setStatus("cocoa", "Cocoa refused: " .. tostring(reason))
    end
end)
-- PANIC ------------------------------------------------------------------
function F.stopAll()
    local n = 0
    for _, h in ipairs(UI.allToggles) do
        if h.get() and h.key ~= "antiafk" and h.key ~= "hatchalerts" then h.set(false, true) n += 1 end
    end
    UI.toast("EVERYTHING STOPPED", ("%d feature%s switched off"):format(n, n == 1 and "" or "s"), THEME.bad)
end
-- MISC: walkspeed ---------------------------------------------------
local walkSpeed = 0
RunService.Heartbeat:Connect(function()
    if not S.on.walkspeed then return end
    local c = LocalPlayer.Character
    local h = c and c:FindFirstChildOfClass("Humanoid")
    if h and walkSpeed > 0 and h.WalkSpeed ~= walkSpeed then h.WalkSpeed = walkSpeed end
end)

----------------------------------------------------------------------
-- BUILD THE PAGES
----------------------------------------------------------------------
do
    local pinnedTab = UI.tab("Pinned", 0)
    UI.pinnedTab = pinnedTab
    local farm = UI.tab("Farm", 1)
    local s = UI.section(farm, "Hatching", THEME.gold)
    UI.toggle(s, "hatch", "Auto Hatch", "Hatches the nearest egg at max amount, no animation", false, function(on) if on then F.startHatch() end end)
    UI.status(s, "hatch", "Off")
    s = UI.section(farm, "Farming", THEME.good)
    UI.toggle(s, "farm", "Fast Farm", "Pets break everything within 100 studs, orbs and lootbags collected", false, function(on) if on then F.startFarm() end end)
    UI.status(s, "farm", "Off")
    UI.toggle(s, "ultimate", "Auto Ultimate", "Fires your equipped ultimate whenever it is charged in a zone", false)
    UI.status(s, "ultimate", "Off")
    UI.toggle(s, "equipbest", "Auto Equip Best", "Re-equips your strongest pets every 30 seconds", false)
    UI.status(s, "equipbest", "Off")
    s = UI.section(farm, "Pumpkin Tycoon", Color3.fromRGB(255, 150, 70))
    UI.toggle(s, "tycoon", "Auto Buy Tycoon", "Buys the cheapest affordable button first, all the way through", false, function(on)
        if on and Tycoon.plot() and UI.handles.tycoonfarm then UI.handles.tycoonfarm.set(true, true) end
    end)
    UI.status(s, "tycoon", "Off")
    UI.toggle(s, "tycoonfarm", "Tycoon Zone Farm", "Farms your highest tycoon zone, moves up when a new one opens", false, function(on)
        if on then Tycoon.startFarm() end
    end)
    UI.status(s, "tycoonfarm", "Off")
    UI.toggle(s, "tycoonupgrades", "Auto Token Upgrades", "Spends Pumpkin Tokens, coin and damage upgrades first", false)
    UI.status(s, "tycoonupgrades", "Off")
    UI.toggle(s, "cocoa", "Auto Hot Cocoa", "Keeps the coins, damage and luck cocoa boosts topped up", false)
    UI.status(s, "cocoa", "Off")
    UI.slider(s, "cocoaMinutes", "Cocoa minutes per top-up", 10, 120, 30, 10)
    s = UI.section(farm, "Tycoon wild pets", Color3.fromRGB(255, 170, 90))
    UI.toggle(s, "wildcatch", "Auto Catch Wild Pets", "Hops to the best wild pet and throws a net, huges first", false)
    UI.status(s, "wildcatch", "Off")
    UI.slider(s, "wildMin", "Only throw at catch chance % or higher", 5, 100, 50, 5)
    UI.toggle(s, "wildultra", "Use Ultra Nets", "5x catch chance; spent on huges and low-chance pets only", false)
    UI.toggle(s, "tycoonautonets", "Auto Buy Nets", "Turns on the tycoon's own net restock (uses Patch Coins)", false, function(on)
        local plot, _, m = Tycoon.plot()
        if plot then
            local ok, a, b = pcall(function() return plot:Invoke(m.Types.NET.SetAutoNets, on) end)
            setStatus("tycoonautonets", (ok and a) and (on and "Tycoon is restocking nets for you" or "Net restock off") or ("Refused: " .. tostring(b or a)))
        else
            setStatus("tycoonautonets", "Join the tycoon to switch this")
        end
    end)
    UI.status(s, "tycoonautonets", "Off")

    -- EGGS: live chances + rare hatch log ---------------------------------
    local eggsTab = UI.tab("Eggs", 2)
    s = UI.section(eggsTab, "Egg chances", THEME.gold)
    do
        local new, corner, stroke, label = UI.new, UI.corner, UI.stroke, UI.label
        local TIERS = {
            { name = "TITANIC", colour = Color3.fromRGB(255, 120, 230) },
            { name = "HUGE", colour = Color3.fromRGB(255, 211, 61) },
            { name = "LEGENDARY", colour = Color3.fromRGB(255, 110, 110) },
            { name = "EPIC", colour = Color3.fromRGB(190, 130, 255) },
            { name = "RARE", colour = Color3.fromRGB(110, 180, 255) },
            { name = "UNCOMMON", colour = Color3.fromRGB(120, 220, 170) },
            { name = "COMMON", colour = Color3.fromRGB(200, 200, 210) },
        }
        local function tierOf(row)
            if row.titanic then return TIERS[1] end
            if row.huge then return TIERS[2] end
            if row.p < 0.0001 then return TIERS[3] end
            if row.p < 0.001 then return TIERS[4] end
            if row.p < 0.01 then return TIERS[5] end
            if row.p < 0.1 then return TIERS[6] end
            return TIERS[7]
        end
        local function pctText(p)
            local pc = p * 100
            if pc >= 10 then return ("%.1f%%"):format(pc) end
            if pc >= 1 then return ("%.2f%%"):format(pc) end
            if pc >= 0.01 then return ("%.3f%%"):format(pc) end
            local digits = math.clamp(math.ceil(-math.log10(pc)) + 2, 4, 12)
            return (("%." .. digits .. "f"):format(pc)):gsub("0+$", "") .. "%"
        end
        local function oneIn(p)
            local inv = 1 / math.max(p, 1e-12)
            return inv < 10 and ("%.1f"):format(inv) or commas(inv)
        end
        local function duration(mins)
            if mins < 1 then return ("%ds"):format(math.max(1, math.floor(mins * 60))) end
            if mins < 60 then return ("%dm"):format(math.floor(mins)) end
            if mins < 1440 then return ("%.1fh"):format(mins / 60) end
            return ("%.1fd"):format(mins / 1440)
        end

        -- header: egg name + egg switcher
        s.n += 1
        local head = new("Frame", { LayoutOrder = s.n, Size = UDim2.new(1, 0, 0, 34), BackgroundTransparency = 1, ZIndex = 4 }, s.frame)
        local eggName = label(head, { text = "No egg nearby", font = Enum.Font.GothamBlack, size = 20, sz = UDim2.new(1, -240, 1, 0), pos = UDim2.fromOffset(4, 0), z = 5 })
        local function pill(x, w, text)
            local b = new("TextButton", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, x, 0.5, 0), Size = UDim2.fromOffset(w, 28),
                BackgroundColor3 = THEME.surface, BackgroundTransparency = 0.25, Text = text, Font = Enum.Font.GothamBold, TextSize = 11,
                TextColor3 = THEME.text, AutoButtonColor = false, ZIndex = 5 }, head)
            corner(b, 14)
            stroke(b, THEME.accent, 0.55)
            return b
        end
        local nextBtn = pill(0, 44, ">")
        local autoBtn = pill(-50, 64, "AUTO")
        local prevBtn = pill(-120, 44, "<")
        local function cycle(dir)
            local list = Chances.eggsInRange()
            if #list == 0 then return end
            local cur = table.find(list, Chances.currentEgg() or "") or 0
            Chances.pinned = list[((cur - 1 + dir) % #list) + 1]
        end
        nextBtn.MouseButton1Click:Connect(function() cycle(1) end)
        prevBtn.MouseButton1Click:Connect(function() cycle(-1) end)
        autoBtn.MouseButton1Click:Connect(function() Chances.pinned = nil end)

        -- stat tiles
        s.n += 1
        local tiles = new("Frame", { LayoutOrder = s.n, Size = UDim2.new(1, 0, 0, 52), BackgroundTransparency = 1, ZIndex = 4 }, s.frame)
        new("UIGridLayout", { CellSize = UDim2.new(0.25, -6, 1, 0), CellPadding = UDim2.fromOffset(8, 0), SortOrder = Enum.SortOrder.LayoutOrder }, tiles)
        local tileValue = {}
        for i, name in ipairs({ "LUCK", "PER HATCH", "EGGS / MIN", "RAREST" }) do
            local tile = new("Frame", { LayoutOrder = i, BackgroundColor3 = THEME.panel, BackgroundTransparency = 0.45, ZIndex = 5 }, tiles)
            corner(tile, 10)
            UI.glassAdd(tile)
            label(tile, { text = name, font = Enum.Font.GothamBold, size = 9, colour = THEME.muted, sz = UDim2.new(1, -16, 0, 14), pos = UDim2.fromOffset(10, 7), z = 6 })
            tileValue[name] = label(tile, { text = "-", font = Enum.Font.GothamBlack, size = 16, sz = UDim2.new(1, -16, 0, 20), pos = UDim2.fromOffset(10, 23), z = 6 })
        end

        -- view filters
        s.n += 1
        local filters = new("Frame", { LayoutOrder = s.n, Size = UDim2.new(1, 0, 0, 26), BackgroundTransparency = 1, ZIndex = 4 }, s.frame)
        new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, filters)
        local view = { rareFirst = Settings.values.eggRareFirst == true, rareOnly = Settings.values.eggRareOnly == true }
        local function chip(order, text, key)
            local b = new("TextButton", { LayoutOrder = order, AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(0, 26), Text = text,
                Font = Enum.Font.GothamBold, TextSize = 10, AutoButtonColor = false, ZIndex = 5 }, filters)
            corner(b, 13)
            UI.pad(b, 12, 12)
            local function paint()
                b.BackgroundColor3 = view[key] and THEME.accent or THEME.surface
                b.BackgroundTransparency = view[key] and 0.05 or 0.35
                b.TextColor3 = view[key] and Color3.fromRGB(40, 14, 30) or THEME.text
            end
            b.MouseButton1Click:Connect(function()
                view[key] = not view[key]
                Settings.values[key == "rareFirst" and "eggRareFirst" or "eggRareOnly"] = view[key]
                persist()
                paint()
                Chances.redraw = true
            end)
            paint()
        end
        chip(1, "RAREST FIRST", "rareFirst")
        chip(2, "HIDE COMMONS", "rareOnly")
        local note = label(filters, { text = "", size = 10, colour = THEME.muted, sz = UDim2.fromOffset(260, 26), z = 5 })
        note.LayoutOrder = 3
        UI.pad(note, 8)

        s.n += 1
        local list = new("Frame", { LayoutOrder = s.n, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, ZIndex = 4 }, s.frame)
        new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, list)
        local empty = label(list, { text = "Stand next to an egg (or turn on Auto Hatch) to see its odds.", size = 12, colour = THEME.muted, sz = UDim2.new(1, 0, 0, 40), z = 5, align = Enum.TextXAlignment.Center })
        local rows = {}
        local function rowFor(i)
            if rows[i] then return rows[i] end
            local r = new("Frame", { LayoutOrder = i, Size = UDim2.new(1, 0, 0, 58), BackgroundColor3 = THEME.panel, BackgroundTransparency = 0.5, ZIndex = 4 }, list)
            corner(r, 12)
            UI.glassAdd(r)
            local rs = stroke(r, THEME.stroke, 0.7)
            local tile = new("Frame", { Position = UDim2.fromOffset(8, 8), Size = UDim2.fromOffset(42, 42), BackgroundColor3 = THEME.surface, BackgroundTransparency = 0.3, ZIndex = 5 }, r)
            corner(tile, 10)
            local tileStroke = stroke(tile, THEME.stroke, 0.3, 1.5)
            local thumb = new("ImageLabel", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(36, 36),
                BackgroundTransparency = 1, ScaleType = Enum.ScaleType.Fit, ZIndex = 6 }, tile)
            local name = label(r, { text = "", font = Enum.Font.GothamBold, size = 14, sz = UDim2.new(1, -260, 0, 18), pos = UDim2.fromOffset(60, 9), z = 5 })
            local tier = new("TextLabel", { Position = UDim2.fromOffset(60, 31), Size = UDim2.fromOffset(0, 16), AutomaticSize = Enum.AutomaticSize.X,
                BackgroundColor3 = THEME.surface, BackgroundTransparency = 0.2, Font = Enum.Font.GothamBlack, TextSize = 9, Text = "", ZIndex = 5 }, r)
            corner(tier, 8)
            UI.pad(tier, 7, 7)
            local odds = label(r, { text = "", size = 11, colour = THEME.muted, sz = UDim2.new(1, -330, 0, 16), pos = UDim2.fromOffset(150, 31), z = 5 })
            local pct = label(r, { text = "", font = Enum.Font.GothamBlack, size = 20, align = Enum.TextXAlignment.Right,
                anchor = Vector2.new(1, 0), sz = UDim2.fromOffset(160, 24), pos = UDim2.new(1, -14, 0, 7), z = 5 })
            local eta = label(r, { text = "", size = 11, colour = THEME.muted, align = Enum.TextXAlignment.Right,
                anchor = Vector2.new(1, 0), sz = UDim2.fromOffset(190, 16), pos = UDim2.new(1, -14, 0, 32), z = 5 })
            local track = new("Frame", { AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 60, 1, -4), Size = UDim2.new(1, -74, 0, 3),
                BackgroundColor3 = THEME.surface, BackgroundTransparency = 0.4, ZIndex = 5 }, r)
            corner(track, 2)
            local fill = new("Frame", { Size = UDim2.fromScale(0, 1), ZIndex = 6 }, track)
            corner(fill, 2)
            rows[i] = { frame = r, stroke = rs, tile = tile, tileStroke = tileStroke, thumb = thumb, name = name, tier = tier, odds = odds, pct = pct, eta = eta, fill = fill }
            return rows[i]
        end
        local function render()
            Chances.refresh()
            local id = Chances.eggId
            if not id or #Chances.rows == 0 then
                eggName.Text = "No egg nearby"
                for _, v in pairs(tileValue) do v.Text = "-" end
                empty.Visible = true
                for _, r in pairs(rows) do r.frame.Visible = false end
                return
            end
            empty.Visible = false
            local per = Chances.perHatch()
            local rate = 0
            local el = os.clock() - S.hatchT0
            if S.on.hatch and el > 5 then rate = (S.eggs - S.eggsAtStart) / el * 60 end
            eggName.Text = id .. (Chances.pinned and "  (pinned)" or "")
            tileValue["LUCK"].Text = "+" .. commas(Chances.luck) .. "%"
            tileValue["LUCK"].TextColor3 = THEME.good
            tileValue["PER HATCH"].Text = commas(per)
            tileValue["EGGS / MIN"].Text = rate > 0 and commas(rate) or "idle"
            local rarest = Chances.rows[#Chances.rows]
            tileValue["RAREST"].Text = rarest and ("1 in " .. oneIn(rarest.p)) or "-"
            tileValue["RAREST"].TextColor3 = rarest and tierOf(rarest).colour or THEME.text
            note.Text = "Odds already include your luck"

            local shown = {}
            for _, row in ipairs(Chances.rows) do
                if not view.rareOnly or row.p < 0.01 or row.huge or row.titanic then shown[#shown + 1] = row end
            end
            if view.rareFirst then table.sort(shown, function(a, b) return a.p < b.p end) end
            for i, row in ipairs(shown) do
                local r = rowFor(i)
                local tierInfo = tierOf(row)
                r.frame.Visible = true
                r.thumb.Image = row.thumb or ""
                r.name.Text = row.id
                r.tier.Text = tierInfo.name
                r.tier.TextColor3 = tierInfo.colour
                r.tileStroke.Color = tierInfo.colour
                r.pct.Text = pctText(row.p)
                r.pct.TextColor3 = tierInfo.colour
                r.fill.BackgroundColor3 = tierInfo.colour
                r.fill.Size = UDim2.fromScale(math.clamp((math.log10(math.max(row.p, 1e-9)) + 7) / 7, 0.02, 1), 1)
                r.odds.Text = ("1 in %s  ·  hatched %s"):format(oneIn(row.p), commas(Tracker.hatched[row.id] or 0))
                local batch = 1 - (1 - row.p) ^ per
                local etaText = batch >= 0.995 and "every hatch" or (batch >= 0.0001 and ("%s per hatch"):format(pctText(batch)) or ("1 in %s per hatch"):format(oneIn(batch)))
                if rate > 0 and row.p < 0.5 then etaText = etaText .. "  ·  ~" .. duration((1 / row.p) / rate) end
                r.eta.Text = etaText
                local special = row.huge or row.titanic
                r.stroke.Color = special and tierInfo.colour or THEME.stroke
                r.stroke.Transparency = special and 0.2 or 0.7
            end
            for i = #shown + 1, #rows do rows[i].frame.Visible = false end
        end
        task.spawn(function()
            while alive() do
                if eggsTab.page.Visible and UI.win.Visible then pcall(render) end
                for _ = 1, 15 do
                    if Chances.redraw then break end
                    task.wait(0.1)
                end
                Chances.redraw = false
            end
        end)
        Chances.pinnedChanged = function() Chances.redraw = true end
        for _, b in ipairs({ nextBtn, prevBtn, autoBtn }) do b.MouseButton1Click:Connect(function() Chances.redraw = true end) end
    end    s = UI.section(eggsTab, "Huge alerts", THEME.gold)
    UI.toggle(s, "hatchalerts", "Huge Alerts", "Toast + log for huges, titanics and gargantuans only", true)
    UI.status(s, "hatchalerts", "")
    UI.toggle(s, "webhook", "Discord Webhook", "Posts every huge, titanic and gargantuan to your Discord channel", false)
    UI.status(s, "webhook", "Off")
    UI.textbox(s, "webhookUrl", "Webhook URL", "https://discord.com/api/webhooks/...", true)
    UI.toggle(s, "webhookping", "Ping Me", "Pings only the Discord user ID below", false)
    UI.textbox(s, "webhookPingId", "Your Discord user ID", "e.g. 123456789012345678 (Developer Mode > Copy User ID)", false)
    UI.button(s, "Send test message", function()
        if not Webhook.url() then
            UI.toast("WEBHOOK", "Paste a Discord webhook URL first", THEME.bad)
            return
        end
        local ok, err = Webhook.send({ tag = "HUGE", name = "Test message (not a real hatch)", amount = 1, egg = Chances.eggId })
        UI.toast("WEBHOOK", ok and "Test sent - check your channel" or ("Failed: " .. tostring(err)), ok and THEME.good or THEME.bad)
        setStatus("webhook", ok and "Test message sent" or ("Webhook failed: " .. tostring(err)))
    end)
    do
        local logLines = {}
        for i = 1, 8 do
            s.n += 1
            local l = UI.label(s.frame, { text = "", size = 11, colour = THEME.muted, sz = UDim2.new(1, 0, 0, 15), z = 4 })
            l.LayoutOrder = s.n
            UI.pad(l, 16)
            logLines[i] = l
        end
        task.spawn(function()
            while alive() do
                for i, l in ipairs(logLines) do
                    local e = Tracker.log[i]
                    l.Text = e and (e.at .. "   " .. e.text) or (i == 1 and "Nothing rare yet this session" or "")
                    l.TextColor3 = e and e.colour or THEME.muted
                end
                task.wait(1)
            end
        end)
    end

    local rewards = UI.tab("Rewards", 3)
    s = UI.section(rewards, "Daily claims", THEME.gold)
    UI.toggle(s, "freegifts", "Auto Free Gifts", "Claims each play-time gift the moment it unlocks", true)
    UI.status(s, "freegifts", "")
    UI.toggle(s, "rankrewards", "Auto Rank Rewards", nil, true)
    UI.status(s, "rankrewards", "")
    UI.toggle(s, "loginstreak", "Auto Login Streak", nil, true)
    UI.status(s, "loginstreak", "")
    UI.toggle(s, "mailbox", "Auto Claim Mailbox", nil, true)
    UI.status(s, "mailbox", "")
    UI.toggle(s, "foreverpack", "Auto Free Pack Slots", "Takes free slots in the Forever Pack, never paid ones", true)
    UI.status(s, "foreverpack", "")
    UI.toggle(s, "daycare", "Auto Collect Daycare", nil, true)
    UI.status(s, "daycare", "")
    UI.toggle(s, "daycareenroll", "Auto Enroll Daycare", "Fills all free slots from one big spare stack, never your best pets", false)
    UI.status(s, "daycareenroll", "")
    UI.toggle(s, "extraclaims", "Auto Extra Claims", "Welcome-back gift, exclusive daycare, transfers, diamond party", true)
    UI.status(s, "extraclaims", "")
    UI.toggle(s, "spinwheel", "Auto Spinny Wheel", "Spends Spinny Wheel Tickets on the spawn wheel (main world)", false)
    UI.status(s, "spinwheel", "")
    s = UI.section(rewards, "Collectibles", THEME.accent)
    UI.toggle(s, "relics", "Auto Shiny Relics", "Finds every shiny relic, no walking needed", true)
    UI.status(s, "relics", "")
    UI.toggle(s, "presents", "Auto Hidden Presents", nil, true)
    UI.status(s, "presents", "")
    UI.toggle(s, "turkeys", "Auto Hidden Turkeys", "Event turkeys, claimed as they stream in near you", true)
    UI.status(s, "turkeys", "")
    s = UI.section(rewards, "Around the world", Color3.fromRGB(140, 210, 255))
    UI.toggle(s, "machines", "Auto Timed Reward Machines", "Hops onto daily diamond / item / potion machines and back", false)
    UI.status(s, "machines", "")
    UI.toggle(s, "balloons", "Auto Balloon Gifts", "Slingshots floating balloons and grabs the gift", false)
    UI.status(s, "balloons", "")
    UI.toggle(s, "vending", "Auto Vending Machines", "Buys out coin vending machines in this world as they restock", false)
    UI.status(s, "vending", "")
    UI.toggle(s, "vendingdiamonds", "Include Diamond Machines", "Rare potion / enchant machines that cost diamonds", false)

    local items = UI.tab("Items", 4)
    s = UI.section(items, "Boosts", THEME.good)
    UI.toggle(s, "potions", "Auto Potions", "Keeps one of every potion type running, best tier first", false)
    UI.status(s, "potions", "")
    UI.toggle(s, "fruits", "Auto Fruit", "Tops up every fruit boost to its limit", false)
    UI.status(s, "fruits", "")
    UI.toggle(s, "toys", "Auto Pet Toys", "Toy ball, toy bone and squeaky toy", false)
    UI.status(s, "toys", "")
    s = UI.section(items, "Open & combine", THEME.gold)
    UI.toggle(s, "lootboxes", "Auto Open Lootboxes", "Gifts and chests in your inventory (skips locked ones)", false)
    UI.status(s, "lootboxes", "")
    UI.toggle(s, "giftbags", "Auto Open Gift Bags & Bundles", nil, false)
    UI.status(s, "giftbags", "")
    UI.toggle(s, "keys", "Auto Combine Key Halves", "Crystal, secret, tech, void and fantasy keys", false)
    UI.status(s, "keys", "")
    s = UI.section(items, "Zone boosters", THEME.accent)
    UI.toggle(s, "flags", "Auto Place Flags", "Keeps every flag type up in the zone you farm", false)
    UI.status(s, "flags", "")
    UI.toggle(s, "sprinklers", "Auto Sprinkler", nil, false)
    UI.status(s, "sprinklers", "")
    UI.toggle(s, "jars", "Auto Coin Jars & Comets", nil, false)
    UI.status(s, "jars", "")
    UI.toggle(s, "tnt", "Auto TNT", nil, false)
    UI.status(s, "tnt", "")

    local pets = UI.tab("Pets", 5)
    s = UI.section(pets, "Machines", THEME.gold)
    UI.toggle(s, "golden", "Auto Golden", "Turns every 10 of a normal pet into a golden one (skips huges)", false)
    UI.status(s, "golden", "")
    UI.toggle(s, "rainbow", "Auto Rainbow", "Turns every 10 goldens into a rainbow (skips huges)", false)
    UI.status(s, "rainbow", "")

    local progress = UI.tab("Progress", 6)
    s = UI.section(progress, "Unlocks", THEME.good)
    UI.toggle(s, "zones", "Auto Buy Next Zone", "Buys the next zone in this world as soon as you can afford it", false)
    UI.status(s, "zones", "")
    UI.toggle(s, "rebirth", "Auto Rebirth", "Rebirths when the next one is available", false)
    UI.status(s, "rebirth", "")
    s = UI.section(progress, "Slots", THEME.gold)
    UI.toggle(s, "equipslots", "Auto Equip Slots", "Buys the next pet equip slot your rank allows", false)
    UI.status(s, "equipslots", "")
    UI.toggle(s, "eggslots", "Auto Egg Slots", "Buys the next egg-hatch slot bundle", false)
    UI.status(s, "eggslots", "")
    UI.slider(s, "slotReserve", "Keep at least (million diamonds)", 0, 50, 2, 1)

    local misc = UI.tab("Misc", 7)
    s = UI.section(misc, "Player", Color3.fromRGB(140, 210, 255))
    UI.toggle(s, "antiafk", "Anti AFK", "Stops Roblox kicking you for idling", true)
    UI.toggle(s, "walkspeed", "Custom Walk Speed", nil, false)
    UI.slider(s, "walkspeedValue", "Walk speed", 16, 120, 40, 1, function(v) walkSpeed = v end)
    s = UI.section(misc, "Interface", THEME.accent)
    UI.slider(s, "glass", "Glass opacity %", 10, 200, 100, 5, function(v) UI.setGlass(v) end)
    UI.keybind(s, "hide", "Show / hide hub", "LeftControl")
    UI.keybind(s, "panic", "Stop everything", "End")
    UI.keybind(s, "palette", "Search palette", "Backquote")
    UI.button(s, "Stop everything now", function() F.stopAll() end)
    UI.toggle(s, "minihud", "Mini HUD while hidden", "A small status pill at the top of the screen when the hub is closed", true)
    s = UI.section(misc, "Session", Color3.fromRGB(140, 210, 255))
    UI.status(s, "session", "")
    s = UI.section(misc, "Hub", THEME.accent)
    UI.button(s, "Claim everything now", function()
        for _, l in ipairs(loops) do
            if table.find({ "freegifts", "rankrewards", "loginstreak", "mailbox", "foreverpack", "relics", "presents", "daycare" }, l.key) then
                task.spawn(pcall, l.fn)
            end
        end
        UI.toast("CLAIMING", "Every daily reward", THEME.gold)
    end)
    UI.button(s, "Unload hub", function() env.__PS99HUB_CLEANUP() end)

    -- PINNED: mirrors of any switch you pinned with its little diamond
    do
        local new, corner, stroke, label = UI.new, UI.corner, UI.stroke, UI.label
        local holder, mirrors = nil, {}
        function UI.refreshPins()
            if holder then holder:Destroy() end
            mirrors = {}
            local sec = UI.section(pinnedTab, "Pinned switches", THEME.gold)
            holder = sec.frame
            local any = false
            for _, h in ipairs(UI.allToggles) do
                if Settings.values["pin_" .. h.key] == true then
                    any = true
                    sec.n += 1
                    local row = new("TextButton", { LayoutOrder = sec.n, Size = UDim2.new(1, 0, 0, 46), BackgroundColor3 = THEME.panel,
                        BackgroundTransparency = 0.62, Text = "", AutoButtonColor = false, ZIndex = 4 }, holder)
                    corner(row, 10)
                    UI.glassAdd(row)
                    local bar = new("Frame", { Position = UDim2.new(0, 6, 0, 8), Size = UDim2.new(0, 3, 1, -16), BackgroundColor3 = THEME.on, ZIndex = 5 }, row)
                    corner(bar, 2)
                    local nm = label(row, { text = h.title, font = Enum.Font.GothamBold, size = 13, sz = UDim2.new(1, -100, 0, 18), pos = UDim2.fromOffset(16, 6), z = 5 })
                    label(row, { text = h.tab.title .. (h.desc and ("  ·  " .. h.desc) or ""), size = 11, colour = THEME.muted, sz = UDim2.new(1, -100, 0, 14), pos = UDim2.fromOffset(16, 25), z = 5 })
                    local track = new("Frame", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0), Size = UDim2.fromOffset(42, 22), ZIndex = 5 }, row)
                    corner(track, 11)
                    local knob = new("Frame", { AnchorPoint = Vector2.new(0, 0.5), Size = UDim2.fromOffset(16, 16), BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 6 }, track)
                    corner(knob, 8)
                    local unpin = new("TextButton", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -62, 0.5, 0), Size = UDim2.fromOffset(22, 22),
                        BackgroundTransparency = 1, Text = "x", Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = THEME.muted, ZIndex = 6 }, row)
                    unpin.MouseButton1Click:Connect(function()
                        Settings.values["pin_" .. h.key] = nil
                        persist()
                        if h.paintPin then h.paintPin() end
                        task.defer(UI.refreshPins)
                    end)
                    row.MouseButton1Click:Connect(function() h.flip() end)
                    mirrors[#mirrors + 1] = { h = h, track = track, knob = knob, bar = bar, name = nm }
                end
            end
            if not any then
                sec.n += 1
                local l = label(holder, { text = "Click the little diamond next to any switch to pin it here.", size = 12, colour = THEME.muted, sz = UDim2.new(1, 0, 0, 30), z = 4 })
                l.LayoutOrder = sec.n
                UI.pad(l, 16)
            end
        end
        UI.refreshPins()
        task.spawn(function()
            while alive() do
                if pinnedTab.page.Visible then
                    for _, m in ipairs(mirrors) do
                        local on = m.h.get()
                        m.track.BackgroundColor3 = on and THEME.on or THEME.surface
                        m.knob.Position = on and UDim2.new(1, -19, 0.5, 0) or UDim2.new(0, 3, 0.5, 0)
                        m.bar.BackgroundTransparency = on and 0 or 1
                        m.name.TextColor3 = on and THEME.text or THEME.muted
                    end
                end
                task.wait(0.3)
            end
        end)
    end

    -- ALERTS: a header chip with a count, opening the last 30 notifications
    do
        local new, corner, stroke, label = UI.new, UI.corner, UI.stroke, UI.label
        local chip = new("TextButton", { LayoutOrder = 0, AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(0, 26),
            BackgroundColor3 = THEME.surface, BackgroundTransparency = 0.45, Text = "ALERTS", Font = Enum.Font.GothamBold, TextSize = 11,
            TextColor3 = THEME.text, AutoButtonColor = false, ZIndex = 3 }, UI.searchChip.Parent)
        corner(chip, 13)
        stroke(chip, THEME.accent, 0.5)
        UI.pad(chip, 12, 12)
        local panel = new("Frame", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -18, 0, 132), Size = UDim2.fromOffset(340, 360),
            BackgroundColor3 = THEME.bg, BackgroundTransparency = 0.06, Visible = false, ZIndex = 150 }, UI.win)
        corner(panel, 14)
        stroke(panel, THEME.accent, 0.4, 1.4)
        label(panel, { text = "NOTIFICATIONS", font = Enum.Font.GothamBlack, size = 13, colour = THEME.accent, sz = UDim2.new(1, -100, 0, 20), pos = UDim2.fromOffset(16, 12), z = 151 })
        local clear = new("TextButton", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 10), Size = UDim2.fromOffset(60, 24),
            BackgroundColor3 = THEME.surface, Text = "CLEAR", Font = Enum.Font.GothamBold, TextSize = 10, TextColor3 = THEME.muted, ZIndex = 151 }, panel)
        corner(clear, 12)
        local list = new("ScrollingFrame", { Position = UDim2.fromOffset(8, 42), Size = UDim2.new(1, -16, 1, -50), BackgroundTransparency = 1, BorderSizePixel = 0,
            ScrollBarThickness = 3, ScrollBarImageColor3 = THEME.accent, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ZIndex = 151 }, panel)
        new("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }, list)
        local function paintChip()
            local n = UI.unread or 0
            chip.Text = n > 0 and ("ALERTS  " .. n) or "ALERTS"
            chip.BackgroundColor3 = n > 0 and THEME.accent or THEME.surface
            chip.TextColor3 = n > 0 and Color3.fromRGB(40, 14, 30) or THEME.text
        end
        local function fill()
            for _, c in ipairs(list:GetChildren()) do if c:IsA("GuiObject") then c:Destroy() end end
            if #UI.history == 0 then
                label(list, { text = "Nothing yet.", size = 12, colour = THEME.muted, sz = UDim2.new(1, 0, 0, 30), z = 152, align = Enum.TextXAlignment.Center })
            end
            for i, h in ipairs(UI.history) do
                local r = new("Frame", { LayoutOrder = i, Size = UDim2.new(1, -6, 0, 42), BackgroundColor3 = THEME.panel, BackgroundTransparency = 0.3, ZIndex = 152 }, list)
                corner(r, 8)
                local strip = new("Frame", { Position = UDim2.fromOffset(6, 8), Size = UDim2.new(0, 3, 1, -16), BackgroundColor3 = h.colour, ZIndex = 153 }, r)
                corner(strip, 2)
                label(r, { text = h.title, font = Enum.Font.GothamBold, size = 12, colour = h.colour, sz = UDim2.new(1, -80, 0, 16), pos = UDim2.fromOffset(16, 5), z = 153 })
                label(r, { text = h.at, size = 10, colour = THEME.muted, align = Enum.TextXAlignment.Right, anchor = Vector2.new(1, 0), sz = UDim2.fromOffset(60, 16), pos = UDim2.new(1, -8, 0, 5), z = 153 })
                label(r, { text = h.body, size = 11, sz = UDim2.new(1, -24, 0, 16), pos = UDim2.fromOffset(16, 22), z = 153 })
            end
        end
        chip.MouseButton1Click:Connect(function()
            panel.Visible = not panel.Visible
            if panel.Visible then UI.unread = 0 fill() end
            paintChip()
        end)
        clear.MouseButton1Click:Connect(function() table.clear(UI.history) UI.unread = 0 fill() paintChip() end)
        UI.onToast = function()
            if panel.Visible then UI.unread = 0 fill() end
            paintChip()
        end
        paintChip()
    end

    -- MINI HUD: a small pill when the hub is hidden
    do
        local new, corner, stroke, label = UI.new, UI.corner, UI.stroke, UI.label
        local pill = new("TextButton", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 8), Size = UDim2.fromOffset(0, 30),
            AutomaticSize = Enum.AutomaticSize.X, BackgroundColor3 = THEME.bg, BackgroundTransparency = 0.2, Text = "", AutoButtonColor = false,
            Visible = false, ZIndex = 40 }, UI.gui)
        corner(pill, 15)
        stroke(pill, THEME.accent, 0.45, 1.3)
        UI.pad(pill, 14, 14)
        new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, VerticalAlignment = Enum.VerticalAlignment.Center,
            Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, pill)
        local dot = new("Frame", { LayoutOrder = 1, Size = UDim2.fromOffset(8, 8), BackgroundColor3 = THEME.on, ZIndex = 41 }, pill)
        corner(dot, 4)
        local txt = new("TextLabel", { LayoutOrder = 2, AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(0, 30), BackgroundTransparency = 1,
            Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = THEME.text, RichText = true, Text = "", ZIndex = 41 }, pill)
        pill.MouseButton1Click:Connect(function() UI.setVisible(true) end)
        task.spawn(function()
            local beat = 0
            while alive() do
                local show = not UI.win.Visible and S.on.minihud ~= false
                pill.Visible = show
                if show then
                    beat += 1
                    local running = 0
                    for _, h in ipairs(UI.allToggles) do if h.get() and h.key ~= "minihud" and h.key ~= "antiafk" and h.key ~= "hatchalerts" then running += 1 end end
                    local parts = { ('<font color="#ff96be">PS99</font>  %d running'):format(running) }
                    local okH, lifetime = pcall(function() return save().EggsHatched end)
                    if okH and tonumber(lifetime) then
                        parts[#parts + 1] = ("%s hatched%s"):format(commas(lifetime), S.eggs > 0 and ((" (+%s)"):format(commas(S.eggs))) or "")
                    end
                    local el = os.clock() - S.hatchT0
                    if S.on.hatch and el > 5 then parts[#parts + 1] = commas((S.eggs - S.eggsAtStart) / el * 60) .. " eggs/min" end
                    if S.on.tycoon and S.status.tycoon then parts[#parts + 1] = S.status.tycoon:gsub("%s+coins$", "") end
                    if Tracker.huges > 0 then parts[#parts + 1] = ('<font color="#ffd33d">%d huge%s</font>'):format(Tracker.huges, Tracker.huges == 1 and "" or "s") end
                    txt.Text = table.concat(parts, "   ·   ")
                    dot.BackgroundTransparency = (running > 0 and beat % 2 == 0) and 0.6 or 0
                    dot.BackgroundColor3 = running > 0 and THEME.on or THEME.muted
                end
                task.wait(1)
            end
        end)
    end

    UI.select(farm, true)
end

----------------------------------------------------------------------
-- LIVE UPDATES
----------------------------------------------------------------------
task.spawn(function()
    local beat = 0
    while alive() do
        for _, line in ipairs(UI.statusLines) do
            local text = S.status[line.key]
            if not S.on[line.key] then text = "Off" end
            if text and line.label.Text ~= text then
                line.label.Text = text
                local low = text:lower()
                local colour = THEME.muted
                if low:find("refused") or low:find("error") or low:find("can't") or low:find("out of") or low:find("missed") then
                    colour = Color3.fromRGB(255, 140, 150)
                elseif low:find("^caught") or low:find("^bought") or low:find("^claimed") or low:find("^hatching") or low:find("^farming")
                    or low:find("^upgraded") or low:find("^enrolled") or low:find("^spun") or low:find("^used") or low:find("^opened") then
                    colour = Color3.fromRGB(150, 230, 170)
                end
                line.label.TextColor3 = colour
            end
        end
        local running = 0
        for _, t in ipairs(UI.tabs) do
            local n = 0
            for _, h in ipairs(t.toggles) do if h.get() then n += 1 end end
            t.badge.Text = tostring(n)
            t.badge.Visible = n > 0
            running += n
        end
        UI.runChip.Text = running > 0 and ("%d RUNNING"):format(running) or "ALL IDLE"
        beat += 1
        UI.pulse.BackgroundColor3 = running > 0 and THEME.on or THEME.muted
        UI.pulse.BackgroundTransparency = (running > 0 and beat % 2 == 0) and 0.5 or 0
        local sv = save()
        if sv then
            local gems
            local ls = LocalPlayer:FindFirstChild("leaderstats")
            for _, v in ipairs(ls and ls:GetChildren() or {}) do
                if v.Name:find("Diamonds") then gems = v.Value end
            end
            UI.chips["DIAMONDS"].Text = gems and short(gems) or "-"
            local el = os.clock() - S.hatchT0
            UI.chips["EGGS / MIN"].Text = (S.on.hatch and el > 1) and commas((S.eggs - S.eggsAtStart) / el * 60) or "0"
            local up = math.floor(os.clock() - S.t0)
            UI.chips["UPTIME"].Text = ("%dh %02dm"):format(up // 3600, (up % 3600) // 60)
            local zone = "-"
            pcall(function() zone = inInstance() or G.MapCmds.GetCurrentZone() or "-" end)
            UI.subtitle.Text = ("%s  ·  %s  ·  rank %s  ·  rebirth %s"):format(LocalPlayer.Name, tostring(zone), tostring(sv.Rank), tostring(sv.Rebirths))
        end
        task.wait(1)
    end
end)

----------------------------------------------------------------------
-- HOTKEY / CLEANUP
----------------------------------------------------------------------
UIS.InputBegan:Connect(function(input)
    if input.UserInputType ~= Enum.UserInputType.Keyboard or UIS:GetFocusedTextBox() then return end
    for _, b in pairs(UI.binds) do if b.busy() then return end end
    local hide, panic = UI.binds.hide.get(), UI.binds.panic.get()
    if hide and input.KeyCode == hide then UI.setVisible(not UI.win.Visible) end
    if panic and input.KeyCode == panic then F.stopAll() end
end)

-- session numbers for the Misc tab
task.spawn(function()
    local gems0, coins0 = nil, nil
    local t0 = os.clock()
    while alive() do
        local gems = diamonds()
        gems0 = gems0 or gems
        local coinsNow
        local plot, _, m = Tycoon.plot()
        if plot then coinsNow = Tycoon.coins(m) coins0 = coins0 or coinsNow end
        local dg = gems - gems0
        local parts = {
            ("Diamonds %s%s"):format(dg >= 0 and "+" or "-", short(math.abs(dg))),
            ("Eggs %s"):format(commas(S.eggs)),
            ("Huges %d"):format(Tracker.huges),
        }
        if coinsNow then parts[#parts + 1] = ("Tycoon coins %s"):format(short(coinsNow)) end
        parts[#parts + 1] = ("Up %dm"):format(math.floor((os.clock() - t0) / 60))
        S.status.session = table.concat(parts, "  ·  ")
        S.on.session = true
        task.wait(2)
    end
end)

env.__PS99HUB_CLEANUP = function()
    S.alive = false
    for k in pairs(S.on) do S.on[k] = false end
    env.__PS99HUB_FARM_ON = false
    pcall(function() G.Variables.OpeningEgg = 0 end)
    pcall(function() UI.sceneHandle.stop() end)
    pcall(function() UI.gui:Destroy() end)
end

UI.toast("PS99 HUB READY", "` search  ·  LeftControl hides the hub", THEME.accent)

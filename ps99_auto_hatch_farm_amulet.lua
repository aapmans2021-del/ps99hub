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
        count = math.max(24, math.floor(count * (opts.detail or 1)))
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
            -- Build the same scene in small batches so creating hundreds of
            -- mountain slices cannot monopolize a single game frame.
            if (i + 1) % 32 == 0 then task.wait() end
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
                local count = math.max(1, math.floor((pass == 1 and 5 or (pass == 2 and 8 or 3)) * (opts.detail or 1) + 0.5))
                for _ = 1, count do
                    local s = r:NextNumber(0.035, 0.075) * (pass == 3 and 0.6 or 1) * ((opts.detail or 1) < 1 and 1.3 or 1)
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
    local frameAcc = 0
    local conn
    conn = RunService.RenderStepped:Connect(function(dt)
        if not scene.Parent then conn:Disconnect() return end
        if opts.active and not opts.active() then return end
        -- frame cap: the scene sits in a CanvasGroup, so every update re-renders it
        local fps = opts.fps and opts.fps() or 60
        frameAcc = frameAcc + dt
        if fps <= 0 then if clock > 0 then return end elseif frameAcc < 1 / fps then return end
        dt = math.min(frameAcc, 0.25)
        frameAcc = 0
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
            if not opts.noSway then t.frame.Rotation = math.sin(clock * 0.7 + t.phase) * 0.7 * wind end
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
-- the game's Directory throws on unknown keys instead of returning nil
local function dirGet(category, key)
    local ok, v = pcall(function() return G.Directory[category][key] end)
    return ok and v or nil
end
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
local invCache, invAt = {}, 0
local function inventoryItems(fresh)
    if not fresh and os.clock() - invAt < 1 then return invCache end
    local ok, list = pcall(function() return G.InventoryCmds.Container():All() end)
    invCache = ok and type(list) == "table" and list or {}
    invAt = os.clock()
    return invCache
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
local function setStatus(key, text)
    if S.status[key] == text then return end
    S.status[key] = text
    -- push straight to the UI (no waiting for the next refresh)
    local push = env.__PS99HUB_PUSH_STATUS
    if push then pcall(push, key, text) end
end

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
    UI.sceneFps = tonumber(Settings.values.sceneFps) or 15
    local sceneHandle = pdBuildScene(sceneHost, { active = shown, fps = function() return UI.sceneFps end, detail = 0.4, noSway = true })
    -- a CanvasGroup re-renders its whole picture whenever anything inside
    -- moves; it is only needed to round the corners. Fullscreen has square
    -- corners, so there the scene lives in a plain clipping frame instead.
    local sceneFlat = new("Frame", { Name = "SceneFlat", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
        ClipsDescendants = true, ZIndex = 0, Visible = false }, win)

    UI.sceneHosts = { round = sceneHost, flat = sceneFlat }
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
    -- scrolls once there are more tabs than fit
    local tabList = new("ScrollingFrame", { Position = UDim2.fromOffset(10, 50), Size = UDim2.new(1, -20, 1, -60), BackgroundTransparency = 1,
        BorderSizePixel = 0, ScrollBarThickness = 3, ScrollBarImageColor3 = THEME.accent, ScrollBarImageTransparency = 0.4,
        CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollingDirection = Enum.ScrollingDirection.Y, ZIndex = 3 }, sidebar)
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
        -- the selected tab is scrolled out of view: hide the marker
        local mid = btn.AbsolutePosition.Y + btn.AbsoluteSize.Y / 2
        if mid < tabList.AbsolutePosition.Y or mid > tabList.AbsolutePosition.Y + tabList.AbsoluteSize.Y then
            glider.Visible = false
            return
        end
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
    tabList:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
        if UI.current then moveGlider(UI.current.button, true) end
    end)
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
            if state and env.__PS99HUB_KICK then env.__PS99HUB_KICK(key) end
            if env.__PS99HUB_REFRESH_COUNTS then pcall(env.__PS99HUB_REFRESH_COUNTS) end
            if env.__PS99HUB_PUSH_STATUS then pcall(env.__PS99HUB_PUSH_STATUS, key, S.status[key] or (state and "Starting..." or "Off")) end
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
            pcall(function()
                UI.sceneHandle.frame.Parent = UI.sceneHosts.flat
                UI.sceneHosts.flat.Visible, UI.sceneHosts.round.Visible = true, false
                -- fullscreen has square corners: the scene fills it edge to edge
                UI.sceneHosts.flat.Position, UI.sceneHosts.flat.Size = UDim2.new(), UDim2.fromScale(1, 1)
            end)
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
            -- windowed: the rounded host (a CanvasGroup) clips the scene to the
            -- window's rounded corners. With the lighter scene it costs nothing
            -- measurable (87 fps rounded vs 86 flat).
            pcall(function()
                UI.sceneHandle.frame.Parent = UI.sceneHosts.round
                UI.sceneHosts.flat.Visible, UI.sceneHosts.round.Visible = false, true
            end)
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
local loops, loopByKey = {}, {}
local function loop(key, interval, fn)
    local l = { key = key, interval = interval, fn = fn, next = 0 }
    loops[#loops + 1] = l
    loopByKey[key] = l
end
-- run a feature right now instead of waiting for its next turn
function F.kick(key)
    local l = loopByKey[key]
    if l then l.next = 0 end
end
env.__PS99HUB_KICK = F.kick
env.__PS99HUB_LOOPS = loops
-- Avoid launching every saved/enabled automation in the same frame. Several
-- features scan the map or inventory, so a small concurrency cap prevents
-- their work from piling up into visible game freezes.
local activeLoopWorkers = 0
local MAX_ACTIVE_LOOP_WORKERS = 3
local nextLoopLaunch = 0
local loopCursor = 1
task.spawn(function()
    while alive() do
        local now = os.clock()
        -- fast lane: tiny, frequent checks (ultimate, tycoon buys, wild throws)
        -- don't wait behind the heavier features
        for _, l in ipairs(loops) do
            if l.interval <= 0.5 and S.on[l.key] and now >= l.next and not l.running then
                l.next = now + l.interval
                l.running = true
                task.spawn(function()
                    local ok, err = pcall(l.fn)
                    if not ok then setStatus(l.key, "error: " .. tostring(err):sub(1, 80)) end
                    l.running = false
                end)
            end
        end
        if activeLoopWorkers < MAX_ACTIVE_LOOP_WORKERS and now >= nextLoopLaunch then
            local total = #loops
            for offset = 0, total - 1 do
                local index = ((loopCursor + offset - 1) % total) + 1
                local l = loops[index]
                if l.interval > 0.5 and S.on[l.key] and now >= l.next and not l.running then
                    l.next = now + l.interval
                    l.running = true
                    activeLoopWorkers += 1
                    nextLoopLaunch = now + 0.08
                    loopCursor = (index % total) + 1
                    task.spawn(function()
                        local t0 = os.clock()
                        local ok, err = pcall(l.fn)
                        local spent = os.clock() - t0
                        if spent > (l.worst or 0) then l.worst = spent end
                        if not ok then setStatus(l.key, "error: " .. tostring(err):sub(1, 80)) end
                        l.running = false
                        activeLoopWorkers = math.max(0, activeLoopWorkers - 1)
                    end)
                    -- Spread launches across scheduler ticks instead of
                    -- starting all due features together; rotate the scan
                    -- start so slower intervals do not starve behind fast ones.
                    break
                end
            end
        end
        task.wait(0.1)
    end
end)
-- react to the save instead of waiting for each loop's timer: a new item,
-- a boost running out or a zone unlock runs the matching features at once
do
    local WAKE = {
        Inventory = { "lootboxes", "eventlootbox", "giftbags", "keys", "golden", "rainbow", "fruits", "potions", "toys", "eventboosts", "daycareenroll" },
        Boosts = { "eventboosts", "potions", "fruits" },
        UnlockedZones = { "zones", "rebirth", "autoquest" },
        Rebirths = { "zones", "autoquest", "equipslots" },
        Goals = { "autoquest" },
        EventPasses = { "eventpass" },
    }
    local pending, queued = {}, false
    local lastKick = {}
    local invSig = nil
    -- coins and diamonds live in the inventory too and change several times a
    -- second while farming; only wake things up when real items change
    local function itemSignature()
        local inv = (save() or {}).Inventory
        if type(inv) ~= "table" then return nil end
        local stacks = 0
        for cls, bag in pairs(inv) do
            if cls ~= "Currency" and cls ~= "Pet" and type(bag) == "table" then
                for _, it in pairs(bag) do
                    stacks += 1 + (type(it) == "table" and (tonumber(it._am) or 1) or 0)
                end
            end
        end
        return stacks
    end
    local conn
    local ok = pcall(function()
        conn = G.Save.StatChanged:Connect(function(stat)
            local keys = WAKE[stat]
            if not keys or not S.alive then return end
            for _, k in ipairs(keys) do pending[k] = stat end
            if queued then return end
            queued = true
            -- coalesce bursts, and never wake the same feature more than
            -- once every 4 seconds
            task.delay(1, function()
                queued = false
                local invChanged = true
                for _, stat2 in pairs(pending) do
                    if stat2 == "Inventory" then
                        local sig = itemSignature()
                        invChanged = sig ~= invSig
                        invSig = sig
                        break
                    end
                end
                local now = os.clock()
                for k, stat2 in pairs(pending) do
                    pending[k] = nil
                    if (stat2 ~= "Inventory" or invChanged) and S.on[k] and now - (lastKick[k] or 0) >= 4 then
                        lastKick[k] = now
                        F.kick(k)
                    end
                end
            end)
        end)
    end)
    invSig = itemSignature()
    if ok and conn then
        task.spawn(function()
            while alive() do task.wait(1) end
            pcall(function() conn:Disconnect() end)
        end)
    end
end

-- EGG FINDER ---------------------------------------------------------
-- Worlds lay their eggs out differently: some name the model after the egg
-- ("Spawn Egg"), newer ones nest numbered capsules ("252 - Egg Capsule")
-- under a world model. Both resolve to the directory id here. Cached 3s.
do
    local byNumber, cache, cachedAt = nil, {}, 0
    local function numberIndex()
        if byNumber then return byNumber end
        byNumber = {}
        pcall(function()
            for id, d in pairs(G.Directory.Eggs) do
                if type(d) == "table" and d.eggNumber and not d.isCustomEgg then byNumber[d.eggNumber] = id end
            end
        end)
        return byNumber
    end
    function F.eggModels()
        if os.clock() - cachedAt < 3 then return cache end
        cachedAt = os.clock()
        local out, seen = {}, {}
        -- ZoneEggs holds the real, placed eggs of the zones around you; the
        -- plain Eggs folder can also hold placeholder capsules parked far away
        for _, folderName in ipairs({ "ZoneEggs", "Eggs" }) do
            local folder = G.THINGS:FindFirstChild(folderName)
            for _, m in ipairs(folder and folder:GetDescendants() or {}) do
                if m:IsA("Model") then
                    local id = dirGet("Eggs", m.Name) and m.Name or nil
                    if not id then
                        local n = tonumber(m.Name:match("^(%d+)%s*%-"))
                        id = n and numberIndex()[n] or nil
                    end
                    if id and not seen[id] then
                        local okP, p = pcall(function() return m:GetPivot().Position end)
                        if okP then
                            seen[id] = true
                            out[#out + 1] = { id = id, pos = p, model = m, dir = dirGet("Eggs", id) }
                        end
                    end
                end
            end
        end
        cache = out
        return out
    end
    function F.eggPosition(id)
        for _, e in ipairs(F.eggModels()) do if e.id == id then return e.pos end end
        return nil
    end
    -- unlock a locked egg (new areas start with theirs locked); retried at
    -- most every 5s per egg
    local unlockTried = {}
    function F.unlockEgg(id)
        local okL, locked = pcall(G.EggCmds.IsEggLocked, id)
        if not (okL and locked) then return true end
        if os.clock() - (unlockTried[id] or 0) < 5 then return false end
        unlockTried[id] = os.clock()
        local ok, res = pcall(G.EggCmds.RequestUnlock, id)
        if ok and res then
            UI.toast("EGG UNLOCKED", id, THEME.good)
            return true
        end
        return false
    end
    -- every area names the egg tied to it (zone.MaximumAvailableEgg)
    function F.areaEgg(zone)
        if type(zone) ~= "table" or not zone.MaximumAvailableEgg then return nil end
        return numberIndex()[zone.MaximumAvailableEgg]
    end
end

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
        for _, egg in ipairs(F.eggModels()) do
            local d = (egg.pos - pos).Magnitude
            if d <= REGULAR_RANGE and (not bestD or d < bestD) then
                local okL, locked = pcall(G.EggCmds.IsEggLocked, egg.id)
                -- a new area's egg starts locked: unlock it, then hatch it
                if okL and locked then locked = not F.unlockEgg(egg.id) end
                if not (okL and locked) then
                    bestD, best = d, { kind = "regular", id = egg.id, key = egg.id, dir = egg.dir }
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
    local skipConn
    skipConn = RunService.Heartbeat:Connect(function()
        if not alive() then skipConn:Disconnect() return end
        if (S.on.hatch or S.lastHatching) and G.Variables.OpeningEgg < 1 then G.Variables.OpeningEgg = 1 end
    end)
    local running = false
    local inFlight = 0
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
                        -- fastest the server allows: it enforces its own cooldown
                        -- (~1.3-1.6s with your mastery) and refusals come back
                        -- instantly and cost nothing. So: send a little before the
                        -- cooldown ends, retry every 60ms until the window opens,
                        -- and learn how early to start from how many tries it took.
                        local okD, cooldown = pcall(G.EggCmds.ComputeDebounce)
                        cooldown = okD and tonumber(cooldown) or 2.5
                        S.hatchLead = S.hatchLead or 0.35
                        local readyAt = (S.lastHatchOk or 0) + cooldown - S.hatchLead
                        while os.clock() < readyAt and S.on.hatch do task.wait(0.02) end
                        local tries, done = 0, false
                        while not done and S.on.hatch and alive() do
                            tries += 1
                            -- keep the "already opening" flag up so the game never
                            -- plays the hatch animation
                            if G.Variables.OpeningEgg < 1 then G.Variables.OpeningEgg = 1 end
                            local sentAt = os.clock()
                            local okH, success, err
                            if egg.kind == "custom" then
                                okH, success, err = pcall(G.Network.Invoke, "CustomEggs_Hatch", egg.key, amount)
                            else
                                okH, success, err = pcall(G.Network.Invoke, "Eggs_RequestPurchase", egg.key, amount)
                            end
                            if okH and success then
                                -- the server's clock started roughly mid-trip
                                S.lastHatchOk = sentAt + (os.clock() - sentAt) / 2
                                S.eggs += amount
                                S.hatches += 1
                                S.shrink = 1
                                -- landed first try: start earlier next time; needed
                                -- many tries: start a bit later
                                if tries == 1 then S.hatchLead = math.min(cooldown * 0.9, S.hatchLead + 0.04)
                                elseif tries > 4 then S.hatchLead = math.max(0, S.hatchLead - 0.04) end
                                setStatus("hatch", ("Hatching %s  ·  %d per hatch  ·  %s eggs"):format(egg.id, amount, commas(S.eggs)))
                                done = true
                            else
                                local raw = okH and tostring(err or success) or tostring(success)
                                local msg = raw:lower()
                                S.hatchFail = raw
                                if msg:find("enough") or msg:find("afford") or msg:find("coins") then
                                    S.shrink = math.min(S.shrink * 2, 64)
                                    setStatus("hatch", ("%s: %s  ·  hatching fewer"):format(egg.id, raw:sub(1, 60)))
                                    done = true
                                elseif tries >= 70 then
                                    setStatus("hatch", ("%s: %s  ·  retrying"):format(egg.id, raw:sub(1, 60)))
                                    done = true
                                else
                                    task.wait(0.06)
                                end
                            end
                        end                    end
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
    -- shared by every farm: send each of your pets to its own breakable with
    -- the game's SetTarget, least-crowded first, and keep it there until it
    -- breaks. `assigned` (euid -> model) persists between calls.
    -- a breakable that spawned after every pet already had one would sit
    -- untouched until something else broke; pull a pet off the most
    -- crowded breakable onto each empty one (nearest pet goes)
    function F.levelLoad(pets, targets, assigned, load, join, posOf)
        local moved = 0
        for _, empty in ipairs(targets) do
            if load[empty] == 0 then
                local crowded
                for _, b in ipairs(targets) do
                    if load[b] >= 2 and (not crowded or load[b] > load[crowded]) then crowded = b end
                end
                if not crowded then break end
                local pick, pickD
                local ep = posOf(empty)
                for _, e in ipairs(pets) do
                    if assigned[e.euid] == crowded then
                        local okP, pp = pcall(function() return e.pet.cpet.primaryPart.Position end)
                        local d = (okP and ep) and (pp - ep).Magnitude or 0
                        if not pickD or d < pickD then pick, pickD = e, d end
                    end
                end
                if pick then
                    load[crowded] -= 1
                    load[empty] = 1
                    assigned[pick.euid] = empty
                    pcall(function() pick.pet:SetTarget(empty) end)
                    join[pick.euid] = empty.Name
                    moved += 1
                end
            end
        end
        return moved > 0
    end
    function F.drivePets(assigned, targets)
        local pets = {}
        local okB, list = pcall(G.PlayerPet.GetByPlayer, LocalPlayer)
        if okB and type(list) == "table" then
            for _, pet in pairs(list) do
                if type(pet) == "table" and pet.euid then pets[#pets + 1] = { euid = pet.euid, pet = pet } end
            end
        end
        if #pets == 0 then
            for euid, pet in pairs(G.PlayerPet.GetAll()) do
                local ok, own = pcall(function() return pet:BelongsToLocalPlayer() end)
                if ok and own then pets[#pets + 1] = { euid = euid, pet = pet } end
            end
        end
        if #targets == 0 or #pets == 0 then return #pets, 0 end
        local isTarget, load = {}, {}
        for _, b in ipairs(targets) do isTarget[b] = true load[b] = 0 end
        for _, e in ipairs(pets) do
            local cur = assigned[e.euid]
            if cur and isTarget[cur] and cur.Parent then load[cur] += 1 end
        end
        local posCache = {}
        local function posOf(b)
            local p = posCache[b]
            if p == nil then
                local ok, bp = pcall(function() return b:GetPivot().Position end)
                p = ok and bp or false
                posCache[b] = p
            end
            return p
        end
        local join, changed = {}, false
        for _, e in ipairs(pets) do
            local cur = assigned[e.euid]
            if not (cur and isTarget[cur] and cur.Parent) then
                local okPos, petPos = pcall(function() return e.pet.cpet.primaryPart.Position end)
                local best, bestLoad, bestD
                for _, b in ipairs(targets) do
                    local l = load[b]
                    if not bestLoad or l <= bestLoad then
                        local bp = okPos and posOf(b)
                        local d = bp and (bp - petPos).Magnitude or 0
                        if not bestLoad or l < bestLoad or d < bestD then best, bestLoad, bestD = b, l, d end
                    end
                end
                if best then
                    load[best] += 1
                    assigned[e.euid] = best
                    pcall(function() e.pet:SetTarget(best) end)
                    join[e.euid] = best.Name
                    changed = true
                end
            end
        end
        if F.levelLoad(pets, targets, assigned, load, join, posOf) then changed = true end
        local present = {}
        for _, e in ipairs(pets) do present[e.euid] = true end
        for euid in pairs(assigned) do if not present[euid] then assigned[euid] = nil end end
        if changed then pcall(G.Network.Fire, "Breakables_JoinPetBulk", join) end
        pcall(G.Network.UnreliableFire, "Breakables_PlayerDealDamage", targets[math.random(#targets)].Name)
        local busy = 0
        for _, l in pairs(load) do if l > 0 then busy += 1 end end
        return #pets, busy
    end
    function F.releasePets()
        local okB, list = pcall(G.PlayerPet.GetByPlayer, LocalPlayer)
        for _, pet in pairs(okB and type(list) == "table" and list or {}) do pcall(function() pet:ClearTarget() end) end
    end

    -- Fast Pets: x200 pet movement everywhere (main world, tycoon, any area),
    -- no matter which farm is running; just its own switch
    task.spawn(function()
        while alive() do
            env.__PS99HUB_FARM_ON = S.on.fastpets ~= false
            task.wait(0.5)
        end
        env.__PS99HUB_FARM_ON = false
    end)

    local running = false
    function F.startFarm()
        if running then return end
        running = true
        task.spawn(function()
            local breakFolder = G.THINGS:WaitForChild("Breakables", 10)
            local conns = {}
            local hits = 0
            -- euid -> breakable model this pet is working on
            local assigned = {}
            pcall(function() S.hasVip = require(RS.Library.Client.Gamepasses).Owns("VIP") == true end)
            local function myPets()
                local out = {}
                local okB, list = pcall(G.PlayerPet.GetByPlayer, LocalPlayer)
                if okB and type(list) == "table" then
                    for _, pet in pairs(list) do
                        if type(pet) == "table" and pet.euid then out[#out + 1] = { euid = pet.euid, pet = pet } end
                    end
                    if #out > 0 then return out end
                end
                for euid, pet in pairs(G.PlayerPet.GetAll()) do
                    local ok, own = pcall(function() return pet:BelongsToLocalPlayer() end)
                    if ok and own then out[#out + 1] = { euid = euid, pet = pet } end
                end
                return out
            end
            local function usable(b)
                return b:IsA("Model") and b.Parent == breakFolder
                    and (S.hasVip or not tostring(b:GetAttribute("BreakableID") or ""):find("VIP", 1, true))
            end
            while S.on.farm and alive() and breakFolder do
                while S.on.tycoonfarm and S.on.farm and alive() and Tycoon.plot() do
                    setStatus("farm", "Paused - Tycoon Zone Farm is running")
                    task.wait(1)
                end
                local root = hrp()
                -- the whole area: the quest's area if one is locked, otherwise
                -- the area you are standing in (any distance inside it)
                local zoneLock, focusWords = S.farmZone or S.areaFarmZone, S.farmFocus
                local area = zoneLock
                -- the event island: the game still reports a main-world zone
                -- there, so use the area of YOUR island you're standing in
                -- (breakables tagged "<Section>_Zone_<your plot>")
                local islandArea
                -- the game's own Auto Farm: if it's on, farm the area it was
                -- set in and stay there, even when you walk somewhere else
                local autoFarmArea = false
                if not area then
                    local okE, enabled = pcall(function() return require(RS.Library.Client.AutoFarmCmds).IsEnabled() end)
                    if okE and enabled then
                        local okZ, part = pcall(function() return require(RS.Library.Client.AutoFarmCmds).GetWholeFarmZone() end)
                        if okZ and typeof(part) == "Instance" then
                            local plots = G.THINGS:FindFirstChild("Plots")
                            local plotModel = plots and part:IsDescendantOf(plots) and part
                            while plotModel and plotModel.Parent ~= plots do plotModel = plotModel.Parent end
                            if plotModel then
                                -- event island: "<Section>_Zone" + "_<plot>"
                                islandArea = part.Name .. "_" .. plotModel.Name
                            else
                                -- main world: the "<n> | <Area name>" folder above the floor
                                local f = part
                                while f and f.Parent and not f.Name:match("^%d+%s*|%s*.+$") do f = f.Parent end
                                area = f and f.Name:match("^%d+%s*|%s*(.+)$") or nil
                            end
                            autoFarmArea = (islandArea or area) ~= nil
                        end
                        if not autoFarmArea then
                            local okP, parentId = pcall(function() return require(RS.Library.Client.AutoFarmCmds).GetTargetParentId() end)
                            if okP and type(parentId) == "string" and parentId ~= "PumpkinTycoon" then area, autoFarmArea = parentId, true end
                        end
                    end
                end
                if not area and not islandArea and root then
                    local _, myModel = Tycoon.plot()
                    if myModel then
                        local suffix = "_" .. myModel.Name
                        local best, bestD
                        for _, b in ipairs(breakFolder:GetChildren()) do
                            local a = b:GetAttribute("AreaID")
                            if type(a) == "string" and a:sub(-#suffix) == suffix then
                                local okP, pos = pcall(function() return b:GetPivot().Position end)
                                if okP then
                                    local d = (pos - root.Position).Magnitude
                                    if not bestD or d < bestD then best, bestD = a, d end
                                end
                            end
                        end
                        islandArea = best
                    end
                end
                if not area and not islandArea then
                    local okZ, cz = pcall(function() return G.MapCmds.GetCurrentZone() end)
                    area = okZ and cz or nil
                end
                local valid, focus = {}, {}
                if root then
                    for _, b in ipairs(breakFolder:GetChildren()) do
                        if usable(b) then
                            local ok
                            if islandArea then
                                ok = b:GetAttribute("AreaID") == islandArea
                            elseif area then
                                ok = b:GetAttribute("ParentID") == area
                            else
                                local okP, pos = pcall(function() return b:GetPivot().Position end)
                                ok = okP and (root.Position - pos).Magnitude <= BREAK_RANGE
                            end
                            if ok then
                                valid[#valid + 1] = b
                                local isFocus = false
                                if focusWords then
                                    local bid = tostring(b:GetAttribute("BreakableID") or "")
                                    for _, w in ipairs(focusWords) do
                                        if bid:find(w, 1, true) then isFocus = true break end
                                    end
                                end

                                if isFocus then focus[#focus + 1] = b end
                            end
                        end
                    end
                end
                local pets = myPets()
                local targets = #focus > 0 and focus or valid
                if #targets > 0 and #pets > 0 then
                    -- spread: every pet gets its own breakable (least crowded
                    -- first) and keeps it until it breaks; pets are sent with the
                    -- game's own SetTarget so they really fly across the area
                    local isTarget, load = {}, {}
                    for _, b in ipairs(targets) do isTarget[b] = true load[b] = 0 end
                    for _, entry in ipairs(pets) do
                        local cur = assigned[entry.euid]
                        if cur and isTarget[cur] and cur.Parent then load[cur] += 1 end
                    end
                    local join, changed = {}, false
                    -- positions looked up once per tick, only if a pet needs a target
                    local posCache = {}
                    local function posOf(b)
                        local p = posCache[b]
                        if p == nil then
                            local okB, bp = pcall(function() return b:GetPivot().Position end)
                            p = okB and bp or false
                            posCache[b] = p
                        end
                        return p
                    end
                    for _, entry in ipairs(pets) do
                        local cur = assigned[entry.euid]
                        if not (cur and isTarget[cur] and cur.Parent) then
                            -- least-loaded breakable; ties go to the one nearest
                            -- this pet so they fan out instead of crossing paths
                            local okPos, petPos = pcall(function() return entry.pet.cpet.primaryPart.Position end)
                            local best, bestLoad, bestD
                            for _, b in ipairs(targets) do
                                local l = load[b]
                                local d = 0
                                if okPos and l <= (bestLoad or math.huge) then
                                    local bp = posOf(b)
                                    d = bp and (bp - petPos).Magnitude or 0
                                end
                                if not bestLoad or l < bestLoad or (l == bestLoad and d < bestD) then best, bestLoad, bestD = b, l, d end
                            end
                            if best then
                                load[best] += 1
                                assigned[entry.euid] = best
                                pcall(function() entry.pet:SetTarget(best) end)
                                join[entry.euid] = best.Name
                                changed = true
                            end
                        end
                    end
                    if F.levelLoad(pets, targets, assigned, load, join, posOf) then changed = true end
                    -- forget pets that were unequipped
                    local present = {}
                    for _, entry in ipairs(pets) do present[entry.euid] = true end
                    for euid in pairs(assigned) do if not present[euid] then assigned[euid] = nil end end
                    if changed then pcall(G.Network.Fire, "Breakables_JoinPetBulk", join) end
                    pcall(G.Network.UnreliableFire, "Breakables_PlayerDealDamage", targets[math.random(#targets)].Name)
                    hits += 1
                    if hits % 15 == 0 then
                        local busy = 0
                        for _, l in pairs(load) do if l > 0 then busy += 1 end end
                        setStatus("farm", ("Farming %s%s  ·  %d pets on %d of %d breakables%s"):format(tostring(islandArea and islandArea:gsub("_Zone_%d+$", "") or area or "nearby"),
                            autoFarmArea and " (Auto Farm area)" or "", #pets, busy, #targets,
                            #focus > 0 and "  ·  quest targets first" or ""))
                    end
                    task.wait(0.1)
                else
                    setStatus("farm", area and ("Waiting for breakables in " .. tostring(area)) or "No breakables nearby")
                    task.wait(0.5)
                end
            end
            -- hand the pets back to the game
            for _, entry in ipairs(myPets()) do pcall(function() entry.pet:ClearTarget() end) end
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
    loop("ultimate", 0.2, function()
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
    -- island farming is capped by how fast breakables respawn (pets already
    -- clear them as they appear), so faster spawns come first, then coins
    local UPGRADE_ORDER = { "RespawnSpeed", "PumpkinCoins", "SpawnLuck", "PumpkinDamage", "EggLuck", "ChaseOdds", "StockSlots", "MerchantLuck" }

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

    loop("tycoon", 0.25, function()
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
                    -- a new area was bought: pets (and the game's Auto Farm) move there
                    Tycoon.moveToNewArea = true
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

    loop("tycoonupgrades", 0.5, function()
        local plot, _, m = Tycoon.plot()
        if not plot then return setStatus("tycoonupgrades", "Join the Pumpkin Tycoon event to use this") end
        local okT, tokens = pcall(m.UpgradesClient.Tokens)
        tokens = okT and tonumber(tokens) or 0
        local best, cheapest
        for _, id in ipairs(UPGRADE_ORDER) do
            if m.Upgrades.ROWS[id] and not best then
                local tier = m.UpgradesClient.Tier(id) or 0
                local okMax, max = pcall(m.UpUtil.MaxTier, id)
                if okMax and tier < max then
                    local okC, cost = pcall(m.UpgradesClient.Cost, id, tier + 1)
                    if okC and type(cost) == "number" then
                        if cost <= tokens then best = { id = id, cost = cost, tier = tier + 1 }
                        elseif not cheapest or cost < cheapest.cost then cheapest = { id = id, cost = cost, tier = tier + 1 } end
                    end
                end
            end
        end
        if not best then
            if not cheapest then return setStatus("tycoonupgrades", "Every token upgrade is maxed") end
            return setStatus("tycoonupgrades", ("Saving for %s tier %d  ·  %d / %d tokens"):format(cheapest.id, cheapest.tier, tokens, cheapest.cost))
        end
        local ok, success, reason = pcall(function() return plot:Invoke(m.UpgradesClient.VERB_BUY, best.id) end)
        if ok and success == true then
            S.counts.tycoon += 1
            setStatus("tycoonupgrades", ("%s -> tier %d for %d tokens"):format(best.id, best.tier, best.cost))
        else
            setStatus("tycoonupgrades", ("%s refused: %s"):format(best.id, tostring(reason or success)))
        end
    end)

    -- zone farm: stand in the best zone, pets on every breakable there
    local running = false
    function Tycoon.startFarm()
        if running then return end
        running = true
        task.spawn(function()
            local section, slab, zoneName, lastTp, spot, eggName = nil, nil, nil, 0, nil, nil
            local hits, prefix = 0, nil
            local assigned = {}
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
                        -- exact area of YOUR island: "<Section>_Zone_<your plot>";
                        -- other players' islands share the same prefix
                        local _, myModel = Tycoon.plot()
                        prefix = (section and myModel) and (section .. "_Zone_" .. myModel.Name) or nil
                        spot = slab and Tycoon.standSpot(slab, eggName) or nil
                        Tycoon.spot, Tycoon.eggName = spot, eggName
                        lastTp = 0
                    end
                    local root = hrp()
                    -- the game's own Auto Farm wins: farm the area it was set in
                    -- and never move you (teleporting would switch it off)
                    local afPrefix
                    -- just bought a new area: go there and re-start the game's Auto
                    -- Farm from inside it, so everything moves to the new area
                    if Tycoon.moveToNewArea and spot and root and not moving then
                        Tycoon.moveToNewArea = false
                        local AF
                        pcall(function() AF = require(RS.Library.Client.AutoFarmCmds) end)
                        local hadAutoFarm = AF and select(2, pcall(AF.IsEnabled)) == true
                        root.AssemblyLinearVelocity = Vector3.zero
                        root.CFrame = spot
                        lastTp = os.clock()
                        task.wait(1)
                        if AF and hadAutoFarm then
                            pcall(AF.Disable)
                            task.wait(0.3)
                            pcall(AF.Enable)
                        end
                        UI.toast("NEW AREA", ("Pets moved to %s"):format(tostring(zoneName or section)), THEME.good)
                    end
                    pcall(function()
                        local AF = require(RS.Library.Client.AutoFarmCmds)
                        if AF.IsEnabled() then
                            local part = AF.GetWholeFarmZone()
                            local _, myModel = Tycoon.plot()
                            if typeof(part) == "Instance" and myModel and part:IsDescendantOf(myModel) then
                                afPrefix = part.Name .. "_" .. myModel.Name
                            end
                        end
                    end)
                    Tycoon.autoFarmArea = afPrefix
                    if not afPrefix and spot and root and not moving then
                        local off = root.Position - spot.Position
                        if Vector3.new(off.X, 0, off.Z).Magnitude > 6 and os.clock() - lastTp > 3 then
                            root.AssemblyLinearVelocity = Vector3.zero
                            root.CFrame = spot
                            lastTp = os.clock()
                        end
                    end
                    local valid = {}
                    local useArea = afPrefix or prefix
                    if useArea then
                        for _, b in ipairs(G.THINGS.Breakables:GetChildren()) do
                            local area = b:GetAttribute("AreaID")
                            if b:IsA("Model") and area == useArea then valid[#valid + 1] = b end
                        end
                    end
                    -- same fast targeting as Fast Farm: every pet on its own
                    -- breakable via the game's SetTarget, kept until it breaks
                    local petCount, busy = F.drivePets(assigned, valid)
                    if #valid > 0 and petCount > 0 then
                        hits += 1
                        if hits % 15 == 0 then
                            setStatus("tycoonfarm", afPrefix and ("Farming %s (your Auto Farm area)  ·  %d pets on %d of %d breakables"):format((afPrefix:gsub("_Zone_%d+$", "")), petCount, busy, #valid)
                                or ("Farming %s  ·  %d pets on %d of %d breakables"):format(tostring(zoneName or section), petCount, busy, #valid))
                        end
                        task.wait(0.1)
                    else
                        setStatus("tycoonfarm", ("Waiting for breakables in %s"):format(tostring(zoneName or section or "-")))
                        task.wait(0.5)
                    end
                end
            end
            if lootConn then lootConn:Disconnect() end
            F.releasePets()
            running = false
        end)
    end
end
-- EQUIP BEST / ANTI AFK ----------------------------------------------
loop("equipbest", 8, function()

    if G.PetCmds and pcall(G.PetCmds.EquipBest) then setStatus("equipbest", "Equipped your best pets  ·  " .. os.date("%H:%M")) end
end)
-- ANTI AFK (same as the Pet Dimensions hub): a real Space key press through
-- VirtualInputManager every N minutes, which resets both Roblox's 20 minute
-- kick and the game's own idle detection. Idled is kept as a backup.
do
    local VIM = game:GetService("VirtualInputManager")
    local VU = game:GetService("VirtualUser")
    local function press()
        pcall(function()
            VIM:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
            task.wait(0.1)
            VIM:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
        end)
        S.afkPresses = (S.afkPresses or 0) + 1
        setStatus("antiafk", ("Pressed Space %d time%s  ·  last %s"):format(S.afkPresses, S.afkPresses == 1 and "" or "s", os.date("%H:%M:%S")))
    end
    F.afkPress = press
    task.spawn(function()
        while alive() do
            if S.on.antiafk then
                local interval = math.max(0.1, tonumber(Settings.values.afkMinutes) or 1) * 60
                local elapsed = 0
                while S.on.antiafk and alive() and elapsed < interval do
                    local step = math.min(1, interval - elapsed)
                    task.wait(step)
                    elapsed += step
                end
                if S.on.antiafk and alive() then press() end
            else
                task.wait(0.25)
            end
        end
    end)
    LocalPlayer.Idled:Connect(function()
        if S.on.antiafk then
            pcall(function() VU:CaptureController() VU:ClickButton2(Vector2.new()) end)
            press()
        end
    end)
end

-- REWARDS ------------------------------------------------------------
loop("freegifts", 2, function()
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
loop("rankrewards", 5, function()
    fire("Ranks_ClaimAll")
    setStatus("rankrewards", "Rank rewards claimed  ·  rank " .. tostring(save().Rank))
end)
loop("loginstreak", 60, function()
    local ok, msg = invoke("Login Streaks: Claim")
    setStatus("loginstreak", ok and "Claimed today's streak" or ("Waiting  ·  " .. tostring(msg or "already claimed")))
end)
loop("mailbox", 20, function()
    local ok, msg = invoke("Mailbox: Claim All")
    setStatus("mailbox", ok and "Claimed all mail" or tostring(msg or "No mail"))
end)
loop("foreverpack", 10, function()
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
loop("relics", 20, function()
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
    loop("presents", 10, function()
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
loop("turkeys", 2, function()
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
loop("daycare", 5, function()
    if G.DaycareCmds and pcall(G.DaycareCmds.Claim) then setStatus("daycare", "Collected finished daycare pets  ·  " .. os.date("%H:%M")) end
end)

-- timed reward machines in this world: hop on, claim, hop back
loop("machines", 15, function()
    if inInstance() then return setStatus("machines", "Leave the instance to reach the machines") end
    local map = workspace:FindFirstChild("Map")
    if not map then return end
    local sv, now = save(), workspace:GetServerTimeNow()
    local ready = {}
    for _, d in ipairs(map:GetDescendants()) do
        local def = d:IsA("Model") and d.Parent and d.Parent.Name == "Machines" and dirGet("TimedRewards", d.Name)
        if def then
            local ts = (sv.TimedRewardTimestamps or {})[d.Name]
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

-- FREE BUTTON MACHINES -------------------------------------------------------
-- Comet Shower (once a day) and Area Surge (every 15 minutes) are free
-- buttons that only answer when you stand on them; hop on and come back,
-- like the timed reward machines. Each lives in one world: elsewhere the
-- status just says where it is.
function F.findMachine(name)
    local okM, models = pcall(function() return require(RS.Library.Client.MachineCmds).GetModels(name) end)
    if okM and type(models) == "table" then
        for _, m in pairs(models) do
            if typeof(m) == "Instance" and m.Parent then return m end
        end
    end
    local map = workspace:FindFirstChild("Map")
    for _, d in ipairs(map and map:GetDescendants() or {}) do
        if d:IsA("Model") and d.Name == name and d.Parent and d.Parent.Name == "Machines" then return d end
    end
    return nil
end
function F.useMachine(key, machineName, remote, stampField, label)
    if inInstance() then return setStatus(key, label .. " is in the main world") end
    local stamp = tonumber((save() or {})[stampField])
    local left = stamp and (stamp - workspace:GetServerTimeNow()) or 0
    if left > 0 then
        return setStatus(key, ("Next %s in %s"):format(label, left >= 3600 and ("%dh %02dm"):format(left // 3600, (left % 3600) // 60) or ("%dm %02ds"):format(left // 60, math.floor(left % 60))))
    end
    -- the server says which world it's in when you're somewhere else
    local ok, msg = invoke(remote)
    if ok then
        UI.toast(label:upper(), "Started", THEME.good)
        return setStatus(key, label .. " started")
    end
    msg = tostring(msg)
    if not msg:lower():find("far") then return setStatus(key, msg) end
    local m = F.findMachine(machineName)
    local pad = m and (m:FindFirstChild("Pad") or m.PrimaryPart or m:FindFirstChildWhichIsA("BasePart", true))
    if not pad then return setStatus(key, "Can't find the " .. label .. " machine in this world") end
    local result
    withTeleport(function(root)
        root.CFrame = CFrame.new(pad.Position + Vector3.new(0, 4, 0))
        task.wait(0.6)
        result = table.pack(invoke(remote))
    end)
    if result and result[1] then
        UI.toast(label:upper(), "Started", THEME.good)
        setStatus(key, label .. " started")
    else
        setStatus(key, label .. ": " .. tostring(result and result[2] or "busy - retrying"))
    end
end
loop("cometshower", 30, function()
    F.useMachine("cometshower", "CometShower", "CometShower_Activate", "CometShowerTimestamp", "Comet Shower")
end)
loop("areasurge", 20, function()
    F.useMachine("areasurge", "ZoneSurges", "Zone Surges: Activate", "ZoneSurgesTimestamp", "Area Surge")
end)

-- ITEM CREATOR ---------------------------------------------------------------
-- Pick an item from the machine's pool (15k diamonds), finish the quest it
-- gives (Auto Rank Quests works on it too) and claim the item. Picks huge
-- potions first.
local ITEM_CREATOR_PICK = { "Huge", "Daycare Slot Voucher", "Bucket O' Magic", "Magic Shard", "Mini Chest", "Mini Pinata", "Gift Bag" }
loop("itemcreator", 3, function()
    local st = (save() or {}).ItemCreator
    if type(st) ~= "table" then return setStatus("itemcreator", "The Item Creator isn't unlocked yet") end
    if st.Goal and st.GoalCompleted then
        local ok, msg = invoke("Item Creator: Claim")
        if ok then
            S.counts.itemcreator = (S.counts.itemcreator or 0) + 1
            UI.toast("ITEM CREATOR", "Item claimed", THEME.gold)
            return setStatus("itemcreator", ("Claimed  ·  %d this session"):format(S.counts.itemcreator))
        end
        return setStatus("itemcreator", "Claim refused: " .. tostring(msg))
    end
    if st.Goal then
        local g = st.Goal
        local okT, ttl = pcall(function() return require(RS.Library.Client.QuestCmds).MakeTitle(g, true) end)
        return setStatus("itemcreator", ("Quest: %s  ·  %s / %s%s"):format(okT and ttl or ("type " .. tostring(g.Type)), commas(g.Progress or 0), commas(g.Amount or 0),
            S.on.autoquest and "" or "  ·  turn on Auto Rank Quests to finish it for you"))
    end
    if type(st.ItemPool) ~= "table" then return setStatus("itemcreator", "Waiting for the machine") end
    if not S.on.itemcreatorpick then return setStatus("itemcreator", "Pick an item yourself, or turn on Auto Pick below") end
    local cost = 15000
    pcall(function() cost = require(RS.Library.Balancing).Constants.ItemCreatorCost or cost end)
    local keep = tonumber(Settings.values.itemCreatorKeep) or 100000
    if diamonds() < cost + keep then
        return setStatus("itemcreator", ("Needs %s diamonds (keeping %s)"):format(short(cost), short(keep)))
    end
    local bestIndex, bestRank, bestName
    for i, entry in ipairs(st.ItemPool) do
        local id = type(entry) == "table" and type(entry.data) == "table" and entry.data.id
        local rank = id and table.find(ITEM_CREATOR_PICK, id) or (#ITEM_CREATOR_PICK + 1)
        if not bestRank or rank < bestRank then
            bestIndex, bestRank = i, rank
            bestName = ("%sx %s"):format(tostring(entry.data and entry.data._am or 1), tostring(id))
        end
    end
    if not bestIndex then return setStatus("itemcreator", "Nothing in the pool") end
    local ok, msg = invoke("Item Creator: Select", bestIndex)
    if ok then
        UI.toast("ITEM CREATOR", "Picked " .. bestName, THEME.good)
        setStatus("itemcreator", "Picked " .. bestName .. " - its quest is next")
    else
        setStatus("itemcreator", "Pick refused: " .. tostring(msg))
    end
end)

-- balloon gifts: slingshot from below, then stand on the gift
loop("balloons", 6, function()
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
loop("fruits", 4, function()
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
loop("potions", 4, function()
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
-- opens every kind of box each pass in the biggest batch the game allows:
-- instant boxes go up to 100 at once, boxes that drop on the floor shrink
-- their batch whenever the game says there is not enough space
local lootBatch = {}
-- the event's own lootbox goes through the tycoon, not the normal opener
local EVENT_LOOTBOX = "Flannel Gift"
pcall(function() EVENT_LOOTBOX = require(RS.Library.Types.PumpkinTycoon.Buttons).COMPLETION_GIFT or EVENT_LOOTBOX end)
-- Opens as many as the game will take per call: instant boxes go 500 at a
-- time; boxes that land on the floor are tried big-to-small in the same
-- pass (the only limit is free floor space), and the size that worked is
-- remembered and grown. Runs in the fast lane while there is anything left.
loop("lootboxes", 0.5, function()
    if not G.LootboxCmds then return end
    -- cheap check on the save first; the full inventory walk only runs
    -- when there is actually a box to open
    local wantIds = {}
    local bag = ((save() or {}).Inventory or {}).Lootbox
    if type(bag) == "table" then
        for _, it in pairs(bag) do
            local id = type(it) == "table" and it.id
            if type(id) == "string" and id ~= EVENT_LOOTBOX and not id:find("Locked") then wantIds[id] = true end
        end
    end
    if not next(wantIds) then
        return setStatus("lootboxes", ("Nothing left to open  ·  %s this session"):format(commas(S.counts.lootboxes)))
    end
    local opened, kinds = 0, 0
    for _, item in pairs(inventoryItems(true)) do
        local id = itemId(item)
        local okD, dir = false, nil
        if id and wantIds[id] then okD, dir = pcall(function() return item:Directory() end) end
        if id and id ~= EVENT_LOOTBOX and okD and type(dir) == "table" and dirGet("Lootboxes", id) and not id:find("Locked") and not dir.IsCardPack then
            local have = tonumber(item:GetAmount()) or 0
            if have > 0 then
                kinds += 1
                local cap = lootBatch[id] or (dir.Instant and 500 or 100)
                local amt = math.min(have, cap)
                while amt >= 1 do
                    local okC, ok, msg = pcall(G.LootboxCmds.Open, item, amt)
                    if okC and ok then
                        opened += amt
                        S.counts.lootboxes += amt
                        lootBatch[id] = math.min(dir.Instant and 1000 or 200, math.max(cap, amt) + 10)
                        break
                    elseif tostring(msg):lower():find("space") and amt > 1 then
                        amt = math.max(1, math.floor(amt / 2))
                        lootBatch[id] = amt
                    else
                        break
                    end
                end
            end
        end
    end
    if opened > 0 then
        setStatus("lootboxes", ("Opened %d box%s  ·  %s this session"):format(opened, opened == 1 and "" or "es", commas(S.counts.lootboxes)))
    elseif kinds == 0 then
        setStatus("lootboxes", ("Nothing left to open  ·  %s this session"):format(commas(S.counts.lootboxes)))
    end
end)
-- EVENT LOOTBOX: Flannel Gifts (Patch Coins and boosts), opened through the
-- tycoon's own opener, which refuses calls that come too fast
loop("eventlootbox", 1.5, function()
    local okG, Gift = pcall(function() return require(RS.Library.Client.PumpkinTycoonCmds.Gift) end)
    if not okG then return setStatus("eventlootbox", "Only works with the Pumpkin Tycoon event") end
    local item
    for _, it in pairs(inventoryItems(true)) do
        if itemId(it) == EVENT_LOOTBOX then item = it break end
    end
    local have = item and tonumber(item:GetAmount()) or 0
    if have <= 0 then return setStatus("eventlootbox", ("No %ss left  ·  %s opened this session"):format(EVENT_LOOTBOX, commas(S.counts.eventlootbox or 0))) end
    local amt = math.min(have, S.eventLootCap or 50)
    local ok, a, b = pcall(Gift.Open, item, amt)
    if ok and a then
        S.counts.eventlootbox = (S.counts.eventlootbox or 0) + amt
        S.eventLootCap = math.min(200, amt + 10)
        setStatus("eventlootbox", ("Opened %d %s%s  ·  %s this session"):format(amt, EVENT_LOOTBOX, amt == 1 and "" or "s", commas(S.counts.eventlootbox)))
    else
        local why = tostring(ok and b or a)
        if why:lower():find("fast") then
            setStatus("eventlootbox", "Waiting a moment (the tycoon limits how fast gifts open)")
        else
            S.eventLootCap = math.max(1, math.floor(amt / 2))
            setStatus("eventlootbox", "Open refused: " .. why)
        end
    end
end)
do
    local BAGS = { "Gift Bag", "Large Gift Bag", "Seed Bag", "Charm Stone" }
    loop("giftbags", 2, function()
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
loop("toys", 8, function()
    local used = {}
    for _, name in ipairs({ "ToyBall_Consume", "ToyBone_Consume", "SqueakyToy_Consume" }) do
        local ok = invoke(name)
        if ok then used[#used + 1] = name:match("^(%a+)") end
        task.wait(0.4)
    end
    setStatus("toys", #used > 0 and ("Used " .. table.concat(used, ", ")) or "Pet toys still active")
end)
loop("keys", 6, function()
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
loop("flags", 6, function()
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
loop("sprinklers", 10, function()
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
loop("jars", 6, function()
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
loop("tnt", 6, function()
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
loop("golden", 2, function()
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
loop("rainbow", 2, function()
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
-- buy every area you can afford right now, one after another (shared by
-- Auto Buy Next Zone and Auto Area Farm); returns the names bought and why
-- it stopped
function F.buyNextZones(key)
    local bought, why = {}, nil
    for _ = 1, 25 do
        if not S.on[key] then break end
        local okN2, nz = pcall(G.ZoneCmds.GetNextZone)
        if not okN2 or not nz then why = "every zone in this world is open" break end
        local name = type(nz) == "table" and (nz._id or nz.ZoneName) or nz
        local ok, msg = invoke("Zones_RequestPurchase", name)
        if not ok then why = ("next: %s  ·  %s"):format(tostring(name), tostring(msg or "saving up")) break end
        S.counts.zones += 1
        bought[#bought + 1] = tostring(name)
        task.wait(0.15)
    end
    if #bought > 0 then
        UI.toast(#bought == 1 and "ZONE UNLOCKED" or ("%d ZONES UNLOCKED"):format(#bought), bought[#bought], THEME.good)
        -- the best area just moved: re-plan quests and re-target the farm now
        F.kick("autoquest")
        F.kick("areafarm")
    end
    return bought, why
end
loop("zones", 1, function()
    if inInstance() or not G.ZoneCmds then return setStatus("zones", "Zones are bought in the main world") end
    local okN, nextZone = pcall(G.ZoneCmds.GetNextZone)
    if not okN or not nextZone then return setStatus("zones", "Every zone in this world is open") end
    local bought, why = F.buyNextZones("zones")
    if #bought > 0 then
        setStatus("zones", ("Bought %s  ·  %d this session"):format(table.concat(bought, ", "), S.counts.zones))
        F.kick("zones")
    elseif why then
        setStatus("zones", (why:gsub("^%l", string.upper)))
    end
end)
loop("rebirth", 3, function()
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
        for _, egg in ipairs(F.eggModels()) do
            if (egg.pos - root.Position).Magnitude < 160 and not table.find(list, egg.id) then list[#list + 1] = egg.id end
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
loop("equipslots", 4, function()
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
loop("eggslots", 4, function()
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
loop("vending", 20, function()
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
-- Wild pets roam the island with a catch chance each. The server only takes
-- a throw from right next to the pet's spawn spot (phys.At), so a hop goes
-- there under the teleport lock, then chains to other good pets close by
-- before coming home. Ultra nets (x5) are only ever spent on huges and
-- above; a missed huge keeps getting nets until it is caught or leaves.
local function itemCount(id)
    local n = 0
    for _, item in pairs(inventoryItems()) do
        if itemId(item) == id then n += (item:GetAmount() or 0) end
    end
    return n
end
local WildStats = { caught = 0, missed = 0, huges = 0, throws = 0, byPet = {}, lastThrow = 0 }
env.__PS99HUB_WILD = WildStats
do
    local WildUtil
    pcall(function() WildUtil = require(RS.Library.Util.PumpkinTycoonWild) end)
    local function throwCooldown()
        local ok, s = pcall(function() return WildUtil.ThrowSeconds() end)
        return (ok and tonumber(s) or 3) + 0.15
    end
    local function netMult(net)
        local ok, m = pcall(function() return WildUtil.NetMultiplier(net) end)
        if ok and tonumber(m) then return tonumber(m) end
        return net == "Ultra Pet Net" and 5 or 1
    end
    local function hugeTier(petId)
        local d = Chances.petInfo(petId or "")
        return d and (d.huge or d.titanic or d.gargantuan) and true or false
    end

    -- Remember each spawned pet object after its first throw so a miss is
    -- not repeatedly targeted on later scans. A new spawn gets a new object.
    local attemptedPets = {}

    -- Huges always take priority. For other pets, sort by raw spawn chance
    -- (lowest first), not net-adjusted chance. Net multipliers must not make
    -- rare targets look common.
    local function candidates(Wild, plot, nets, ultras, attempted)
        local caughtIds = {}
        pcall(function() caughtIds = plot:Save("CaughtIds") or {} end)
        local all = Wild.All() or {}
        for phys in pairs(attempted) do
            local stillSpawned = false
            for _, current in pairs(all) do
                if current == phys then stillSpawned = true break end
            end
            if not stillSpawned then attempted[phys] = nil end
        end
        local list = {}
        for slot, phys in pairs(all) do
            if type(phys) == "table" and phys.At and not attempted[phys] and not phys.Catching and not phys.AttemptingCatch and not phys.SoldOut then
                local entry = type(phys.Entry) == "table" and phys.Entry or {}
                local huge = hugeTier(entry.P)
                local net
                if huge and ultras > 0 and S.on.wildultrahuge ~= false then net = "Ultra Pet Net"
                elseif nets > 0 then net = "Pet Net" end
                local maxChance = (tonumber(Settings.values.wildMax) or 30) / 100
                local baseChance0 = tonumber(phys.CatchChance) or 1
                -- only the rare ones: skip anything easier than your limit (huges always count)
                if net and not huge and baseChance0 > maxChance then net = nil end
                if net then
                    local baseChance = tonumber(phys.CatchChance) or 0
                    local displayChance = math.min(1, baseChance * netMult(net))
                    local new = S.on.wildnew ~= false and not caughtIds[entry.P]
                    local variantScore = (entry.S and 30 or 0) + (entry.R and 20 or 0) + (entry.G and 10 or 0)
                    list[#list + 1] = {
                        slot = slot, phys = phys, net = net, pet = entry.P or "?",
                        rawChance = baseChance, chance = displayChance, huge = huge,
                        variant = (entry.S and "Shiny " or "") .. (entry.R and "Rainbow " or (entry.G and "Golden " or "")),
                        variantScore = variantScore, new = new,
                    }
                end
            end
        end
        table.sort(list, function(a, b)
            if a.huge ~= b.huge then return a.huge end
            if a.rawChance ~= b.rawChance then return a.rawChance < b.rawChance end
            if a.variantScore ~= b.variantScore then return a.variantScore > b.variantScore end
            if a.new ~= b.new then return a.new end
            return tostring(a.pet) < tostring(b.pet)
        end)
        return list
    end

    local function throwAt(plot, m, root, c)
        local function try(offset)
            root.CFrame = CFrame.new(c.phys.At + offset)
            task.wait(0.55)
            return { pcall(function() return plot:Invoke(m.Types.NET.CatchWild, c.slot, c.net) end) }
        end
        local r = try(Vector3.new(3, 3, 0))
        if r[1] and r[2] ~= true and tostring(r[3]):find("closer") then r = try(Vector3.new(0, 3, 0)) end
        WildStats.lastThrow = os.clock()
        if not (r[1] and r[2] == true) then return nil, tostring(r[3] or r[2]) end
        local outcome = type(r[4]) == "table" and (r[4].outcome or r[4].Outcome) or nil
        return tostring(outcome):lower() == "caught", nil
    end

    loop("wildcatch", 0.5, function()
        local plot, _, m = Tycoon.plot()
        if not plot then return setStatus("wildcatch", "Only works inside the Pumpkin Tycoon") end
        local okW, Wild = pcall(m.Cmds.Feature, "Wild")
        if not (okW and Wild) then return setStatus("wildcatch", "Wild pets unlock with part 2 of the tycoon") end
        local cooldown = throwCooldown()
        if os.clock() - WildStats.lastThrow < cooldown then return end
        local nets, ultras = itemCount("Pet Net"), itemCount("Ultra Pet Net")
        if nets + ultras == 0 then
            if S.on.tycoonautonets then return setStatus("wildcatch", "Out of nets  ·  waiting for the tycoon to restock") end
            return setStatus("wildcatch", "Out of Pet Nets  ·  turn on Auto Buy Nets")
        end
        -- every spawn on your island, straight from its save (loaded or not)
        local maxChance = (tonumber(Settings.values.wildMax) or 30) / 100
        local saved = {}
        pcall(function() saved = plot:Save(m.Types.VAR.Wild) or {} end)
        local loaded = {}
        for slot in pairs(Wild.All() or {}) do loaded[tostring(slot)] = true end
        local rarest, scoutZone
        for slot, w in pairs(saved) do
            if type(w) == "table" and tonumber(w.C) then
                if not rarest or w.C < rarest.C then rarest = w end
                local huge = hugeTier(w.P)
                if (huge or w.C <= maxChance) and not loaded[tostring(slot)] then scoutZone = scoutZone or w.Z end
            end
        end
        -- a rare spawn that isn't streamed in yet: hop to its wild area so it loads
        if scoutZone and os.clock() - (WildStats.lastScout or 0) > 20 then
            WildStats.lastScout = os.clock()
            local _, myModel = Tycoon.plot()
            local area = myModel and myModel:FindFirstChild("WildAreas") and myModel.WildAreas:FindFirstChild("WildArea_" .. tostring(scoutZone))
            if area then
                withTeleport(function(root)
                    root.CFrame = CFrame.new(area.Position + Vector3.new(0, 5, 0))
                    task.wait(1.5)
                end)
            end
        end
        local list = candidates(Wild, plot, nets, ultras, attemptedPets)
        if #list == 0 and nets == 0 then
            return setStatus("wildcatch", ("Out of Pet Nets (%d Ultra kept for huges)%s  ·  turn on Auto Buy Nets"):format(ultras,
                rarest and ("  ·  rarest waiting: %s %d%%"):format(tostring(rarest.P), rarest.C * 100) or ""))
        end
        if #list == 0 then
            return setStatus("wildcatch", ("Nothing at %d%% or rarer right now%s  ·  %d nets  ·  caught %d"):format(maxChance * 100,
                rarest and ("  ·  rarest is %s at %d%%"):format(tostring(rarest.P), rarest.C * 100) or "", nets, WildStats.caught))
        end
        local lastText
        withTeleport(function(root)
            local here = list[1].phys.At
            local thrown = 0
            local i = 1
            while i <= #list and thrown < 5 and S.on.wildcatch and alive() do
                local c = list[i]
                -- chain only to pets close to where we already are
                if thrown > 0 and (c.phys.At - here).Magnitude > 60 then i += 1 continue end
                if thrown > 0 then
                    local wait = cooldown - (os.clock() - WildStats.lastThrow)
                    if wait > 0 then task.wait(wait) end
                end
                if c.phys.Catching or c.phys.SoldOut then i += 1 continue end
                -- One attempt per individual spawned pet, including Huges.
                attemptedPets[c.phys] = true
                local caught, err = throwAt(plot, m, root, c)
                thrown += 1
                here = c.phys.At
                WildStats.throws += 1
                if caught == nil then
                    lastText = ("%s: %s"):format(c.pet, err)
                    i += 1
                elseif caught then
                    WildStats.caught += 1
                    WildStats.byPet[c.pet] = (WildStats.byPet[c.pet] or 0) + 1
                    if c.huge then
                        WildStats.huges += 1
                        UI.toast("HUGE CAUGHT!", c.variant .. c.pet, THEME.gold)
                    else
                        UI.toast("WILD PET CAUGHT", ("%s%s  ·  %d%%"):format(c.variant, c.pet, c.chance * 100), THEME.good)
                    end
                    lastText = ("Caught %s%s (%d%%)"):format(c.variant, c.pet, c.chance * 100)
                    i += 1
                else
                    WildStats.missed += 1
                    lastText = ("Missed %s%s (%d%%)"):format(c.variant, c.pet, c.chance * 100)
                    -- This spawn has now had its single attempt. A later
                    -- newly spawned Huge will still be prioritised normally.
                end
            end
        end)
        setStatus("wildcatch", ("%s  ·  caught %d / %d throws%s"):format(lastText or "Throwing", WildStats.caught, WildStats.throws,
            WildStats.huges > 0 and ("  ·  %d HUGE"):format(WildStats.huges) or ""))
    end)
end
-- EXTRA CLAIMS -------------------------------------------------------------
loop("extraclaims", 30, function()
    local got = {}
    for _, name in ipairs({ "WelcomeBack: Claim", "Exclusive Daycare: Claim", "Transferring_ClaimAll" }) do
        if invoke(name) then got[#got + 1] = name:match("^[^:_]+") end
        task.wait(0.3)
    end
    fire("DiamondParty_Claim")
    setStatus("extraclaims", #got > 0 and ("Claimed " .. table.concat(got, ", ")) or ("Nothing waiting  ·  checked " .. os.date("%H:%M")))
end)

-- SPINNY WHEEL (main world) -------------------------------------------------
loop("spinwheel", 6, function()
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
    -- the world wheels (Tech / Void / Fantasy) take their own tickets; the
    -- server says so when you're in the wrong world, which costs nothing
    local extra = {}
    if S.on.spinwheelworlds then
        for _, w in ipairs({ { "TechWheel", "Tech Spinny Wheel Ticket" }, { "VoidWheel", "Void Spinny Wheel Ticket" }, { "FantasyWheel", "Fantasy Spinny Wheel Ticket" } }) do
            local n = itemCount(w[2])
            for _ = 1, math.min(3, n) do
                local ok = invoke("Spinny Wheel: Request Spin", w[1])
                if not ok then break end
                extra[#extra + 1] = w[1]
                task.wait(5.5)
            end
        end
    end
    setStatus("spinwheel", (spun > 0 and ("Spun %d times  ·  %d tickets left"):format(spun, tickets - spun) or ("Can't spin: " .. tostring(msg)))
        .. (#extra > 0 and ("  ·  %d world-wheel spins"):format(#extra) or ""))
end)

-- FREE WHEEL TICKETS ---------------------------------------------------------
-- Every spinny wheel hands out a free ticket every couple of days. The
-- request works from anywhere (checked live: Tech, Void and Fantasy wheels).
loop("wheeltickets", 120, function()
    local okD, wheels = pcall(function() return G.Directory.SpinnyWheels end)
    if not okD or type(wheels) ~= "table" then return setStatus("wheeltickets", "No spinny wheels found") end
    local cds = (save() or {}).SpinnyWheelCooldowns or {}
    local now = workspace:GetServerTimeNow()
    local asked, soonest = {}, nil
    for id, d in pairs(wheels) do
        if type(d) == "table" and not d.Subtitle then
            local cd = tonumber(cds[id])
            if not cd or cd <= now then
                fire("Spinny Wheel: Request Ticket", id)
                asked[#asked + 1] = (tostring(id):gsub("Wheel$", ""))
            elseif not soonest or cd < soonest then
                soonest = cd
            end
        end
    end
    local nextTxt = soonest and ("next in %dh %02dm"):format((soonest - now) // 3600, ((soonest - now) % 3600) // 60) or ""
    if #asked > 0 then
        setStatus("wheeltickets", "Asked for free tickets: " .. table.concat(asked, ", ") .. (nextTxt ~= "" and ("  ·  " .. nextTxt) or ""))
    else
        setStatus("wheeltickets", "All free tickets claimed  ·  " .. nextTxt)
    end
end)

-- SLOT VOUCHERS --------------------------------------------------------------
-- Daycare and booth slot vouchers each add a permanent +1 slot.
loop("vouchers", 20, function()
    local used, notes = {}, {}
    for _, v in ipairs({ { "Daycare Slot Voucher", "DaycareSlotVoucher_Consume", "daycare slot" }, { "Booth Slot Voucher", "BoothSlotVoucher_Consume", "booth slot" } }) do
        if itemCount(v[1]) > 0 then
            local ok, a = invoke(v[2])
            if ok then
                used[#used + 1] = "+1 " .. v[3]
                invAt = 0
            else
                notes[#notes + 1] = v[1] .. ": " .. tostring(a)
            end
            task.wait(0.5)
        end
    end
    if #used > 0 then UI.toast("VOUCHER", table.concat(used, ", "), THEME.good) end
    setStatus("vouchers", #used > 0 and ("Used " .. table.concat(used, ", ")) or (#notes > 0 and table.concat(notes, "  ·  ") or "No slot vouchers in your bag"))
end)

-- KEY CHESTS -----------------------------------------------------------------
-- Full keys open their chest (up to 100 at a time). Each chest lives in one
-- world and only opens for someone standing at it; the hub hops there and
-- back for whichever chests are in the world you're in.
local KEY_CHESTS = {
    { "Crystal Key", "CrystalKey_Unlock", "Crystal Chest" }, { "Tech Key", "TechKey_Unlock", "Tech Chest" },
    { "Void Key", "VoidKey_Unlock", "Void Chest" }, { "Fantasy Key", "FantasyKey_Unlock", "Fantasy Chest" },
    { "Hacker Key", "HackerKey_Unlock", "Hacker Chest" }, { "MVP Key", "MVPKey_Unlock", "MVP Chest" },
}
loop("keychests", 10, function()
    local CS = game:GetService("CollectionService")
    local keep = tonumber(Settings.values.keyKeep) or 0
    local opened, waiting = {}, {}
    for _, k in ipairs(KEY_CHESTS) do
        local have = itemCount(k[1]) - keep
        if have > 0 then
            local chest
            for _, c in ipairs(CS:GetTagged(k[3])) do if c:IsDescendantOf(workspace) then chest = c break end end
            if chest then
                local n = math.min(100, have)
                local ok, msg = false, nil
                withTeleport(function(root)
                    root.CFrame = CFrame.new(chest:GetPivot().Position + Vector3.new(0, 4, 6))
                    task.wait(0.6)
                    ok, msg = invoke(k[2], n)
                end)
                if ok then
                    opened[#opened + 1] = ("%d %s"):format(n, k[3])
                    invAt = 0
                else
                    waiting[#waiting + 1] = k[3] .. ": " .. tostring(msg)
                end
                task.wait(2.5)
            else
                waiting[#waiting + 1] = ("%d %ss (chest is in another world)"):format(have, k[1])
            end
        end
    end
    if #opened > 0 then UI.toast("KEY CHESTS", "Opened " .. table.concat(opened, ", "), THEME.gold) end
    setStatus("keychests", #opened > 0 and ("Opened " .. table.concat(opened, ", "))
        or (#waiting > 0 and table.concat(waiting, "  ·  ") or "No full keys to use"))
end)
-- DAYCARE ENROLL -----------------------------------------------------------
-- Never touches your best pets: every pet type that makes your top team
-- (strongest copies up to your equip limit) or is equipped right now is off
-- limits. From what is left it picks ONE stack big enough to fill every free
-- slot by itself, the biggest stack first, so the slots fill with fodder.
loop("daycareenroll", 4, function()
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
loop("cocoa", 8, function()
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
-- SEASON PASS ----------------------------------------------------------------
-- Spends Season Tokens on the event pass. A tier opens once enough tokens have
-- been spent, so it buys the cheapest open card until the huge's tier opens,
-- then saves every token for the huge. After that it clears the rest cheapest
-- first.
local Pass = {}
env.__PS99HUB_PASS = Pass
function Pass.read()
    local okU, U = pcall(function() return require(RS.Library.Util.EventPassUtil) end)
    local okC, EP = pcall(function() return require(RS.Library.Client.EventPassCmds) end)
    if not (okU and okC) then return nil end
    local okR, st = pcall(EP.Read)
    if not okR or type(st) ~= "table" then return nil end
    -- Read() hands back its tables as JSON text
    local out = {}
    for k, v in pairs(st) do
        if type(v) == "string" and (v:sub(1, 1) == "{" or v:sub(1, 1) == "[") then
            local okJ, dec = pcall(HttpService.JSONDecode, HttpService, v)
            out[k] = okJ and dec or v
        elseif v == "true" or v == "false" then
            out[k] = v == "true"
        else
            out[k] = v
        end
    end
    st = out
    if not st.HasState or not st.Live then return nil end
    local d = U.Get(U.Current() or "")
    local set = d and (tonumber(st.Week) or 0) > 0 and U.WeekSet(d, st.Week)
    if type(set) ~= "table" or type(set.Tiers) ~= "table" then return nil end
    return st, set, U, EP
end
function Pass.flag(U, fname, r)
    if type(U[fname]) ~= "function" then return false end
    local ok, v = pcall(U[fname], r)
    return ok and v == true
end
function Pass.name(r)
    local ok, item = pcall(r.Item)
    if not ok or not item then return r.Key end
    local okN, n, a = pcall(function() return item:GetName(), item:GetAmount() end)
    if not okN or type(n) ~= "string" then return r.Key end
    return (tonumber(a) or 1) > 1 and ("%sx %s"):format(short(a), n) or n
end
function Pass.plan()
    local st, set, U, EP = Pass.read()
    if not st then return nil end
    local stars, spent = tonumber(st.Stars) or 0, tonumber(st.Spent) or 0
    local unlock = st.TierUnlock or {}
    local owned = st.Owned or {}
    local open, huge, nextTier = {}, nil, nil
    for tier, row in ipairs(set.Tiers) do
        local need = tonumber(unlock[tier])
        local isOpen = need ~= nil and need <= spent
        if not isOpen and need and (not nextTier or need < nextTier.need) then nextTier = { tier = tier, need = need } end
        for _, r in ipairs(row) do
            if type(r) == "table" and r.Key and not owned[r.Key] and not Pass.flag(U, "ComingSoon", r) and not Pass.flag(U, "SoldOut", r) then
                local c = { r = r, tier = tier, open = isOpen, cost = tonumber(r.Cost) or math.huge, key = r.Key }
                if tostring(r.Key):lower():find("huge") or tostring(Pass.name(r)):find("Huge") then
                    if not huge or c.tier < huge.tier then huge = c end
                elseif isOpen then
                    open[#open + 1] = c
                end
            end
        end
    end
    table.sort(open, function(a, b) return a.cost < b.cost end)
    local target, why
    if huge and huge.open then
        target, why = huge, "saving for the huge"
    elseif huge then
        target, why = open[1], ("opening tier %d for the huge (%d / %d spent)"):format(huge.tier, spent, tonumber(unlock[huge.tier]) or 0)
    else
        target, why = open[1], "clearing the rest of the pass"
    end
    return { st = st, EP = EP, stars = stars, spent = spent, huge = huge, target = target, why = why, nextTier = nextTier, buying = st.Buying, timer = st.Timer }
end
loop("eventpass", 15, function()
    local p = Pass.plan()
    if not p then return setStatus("eventpass", "No season pass running right now") end
    if not p.buying then return setStatus("eventpass", "The pass shop is closed (" .. tostring(p.timer or "") .. ")") end
    if not p.target then
        if p.huge then
            return setStatus("eventpass", ("Huge is in tier %d - nothing else open to spend on yet  ·  %d tokens"):format(p.huge.tier, p.stars))
        end
        return setStatus("eventpass", "Everything open is bought  ·  " .. tostring(p.timer or ""))
    end
    local t = p.target
    if p.stars < t.cost then
        return setStatus("eventpass", ("%s: %s needs %d tokens, you have %d"):format(p.why, Pass.name(t.r), t.cost, p.stars))
    end
    local ok, a, b = pcall(p.EP.Buy, t.key)
    if ok and a then
        UI.toast("SEASON PASS", "Bought " .. Pass.name(t.r), t == p.huge and THEME.gold or THEME.good)
        setStatus("eventpass", ("Bought %s for %d tokens  ·  %s"):format(Pass.name(t.r), t.cost, p.why))
        F.kick("eventpass")
    else
        setStatus("eventpass", "Buy refused: " .. tostring(ok and b or a))
    end
end)
-- EVENT BOOSTS ---------------------------------------------------------------
-- Keeps a Patch Coin, Pumpkin Damage and Island Luck boost running from your
-- inventory. Only starts one when that kind has run out, best tier first, so
-- nothing gets wasted on top of a boost that is still going.
loop("eventboosts", 6, function()
    local okB, PB = pcall(function() return require(RS.Library.Util.PumpkinTycoonBoosts) end)
    local okC, CC = pcall(function() return require(RS.Library.Client.ConsumableCmds) end)
    if not (okB and okC) then return setStatus("eventboosts", "Event boosts aren't in this game version") end
    local boosts = (save() or {}).Boosts or {}
    local function left(axis)
        local best = 0
        for _, id in ipairs(PB.IDS[axis] or {}) do
            for _, b in pairs(boosts[id] or {}) do
                if type(b) == "table" then best = math.max(best, tonumber(b.remaining) or 0) end
            end
        end
        return best
    end
    local items = inventoryItems(true)
    local used, parts = {}, {}
    for _, axis in ipairs(PB.AXES) do
        local name = PB.ITEMS[axis]
        local remain = left(axis)
        if remain < 20 then
            local pick, pickTier
            for _, it in pairs(items) do
                if itemId(it) == name then
                    local okT, tier = pcall(function() return it:GetTier() end)
                    tier = okT and tonumber(tier) or 1
                    if (tonumber(it:GetAmount()) or 0) > 0 and (not pickTier or tier > pickTier) then pick, pickTier = it, tier end
                end
            end
            if pick then
                local ok, a, b = pcall(CC.Consume, pick, 1)
                if ok and a then
                    used[#used + 1] = ("%s %s"):format(name, ({ "I", "II", "III" })[pickTier] or tostring(pickTier))
                    remain = 1
                else
                    parts[#parts + 1] = name .. ": " .. tostring(ok and b or a)
                end
                task.wait(0.4)
            else
                parts[#parts + 1] = "no " .. name
            end
        end
        if remain >= 20 then
            parts[#parts + 1] = ("%s %dm"):format(axis, math.floor(remain / 60))
        end
    end
    if #used > 0 then
        UI.toast("BOOSTS", "Started " .. table.concat(used, ", "), THEME.good)
        invAt = 0
    end
    setStatus("eventboosts", (#used > 0 and ("Started " .. table.concat(used, ", ") .. "  ·  ") or "") .. table.concat(parts, "  ·  "))
end)
-- TURKEY SIGHTINGS state
local Turkey = {}
env.__PS99HUB_TURKEY = Turkey
-- TURKEY SIGHTINGS -----------------------------------------------------------
-- A rare wild pet (huge or better) that wanders on your island for a short
-- time. It's always worth an Ultra Net, so it gets one if you have any.
loop("turkeysighting", 2, function()
    local okT, Tk = pcall(function() return require(RS.Library.Client.PumpkinTycoonCmds.Turkey) end)
    if not okT then return setStatus("turkeysighting", "Only works inside the Pumpkin Tycoon") end
    local expires = Tk.Sighting()
    if not expires then
        Turkey.sightTries = 0
        return setStatus("turkeysighting", "No sighting on your island right now" .. (Turkey.lastSight and ("  ·  last: " .. Turkey.lastSight) or ""))
    end
    local okU, cur = pcall(debug.getupvalue, Tk.Sighting, 1)
    if not okU or type(cur) ~= "table" or typeof(cur.spot) ~= "Vector3" then
        return setStatus("turkeysighting", "Sighting up, but its spot isn't readable")
    end
    local petId = type(cur.entry) == "table" and tostring(cur.entry.P) or "?"
    local nets = { pet = 0, ultra = 0 }
    for _, it in pairs(inventoryItems(true)) do
        local id = itemId(it)
        if id == "Pet Net" then nets.pet += tonumber(it:GetAmount()) or 0 end
        if id == "Ultra Pet Net" then nets.ultra += tonumber(it:GetAmount()) or 0 end
    end
    local net = nets.ultra > 0 and "Ultra Pet Net" or (nets.pet > 0 and "Pet Net") or nil
    if not net then return setStatus("turkeysighting", petId .. " is out - no nets left to throw") end
    if (Turkey.sightTries or 0) >= 6 then return setStatus("turkeysighting", petId .. ": gave up after 6 throws") end
    local result, why
    withTeleport(function(root)
        root.CFrame = CFrame.new(cur.spot + Vector3.new(0, 3, 0))
        task.wait(0.5)
        local ok, a, b = pcall(Tk.Throw, net)
        result, why = ok and a, ok and b or a
        task.wait(0.8)
    end)
    Turkey.sightTries = (Turkey.sightTries or 0) + 1
    if result then
        Turkey.lastSight = ("%s (%s, %s)"):format(petId, net, tostring(why or "thrown"))
        UI.toast("SIGHTING", ("Threw a %s at %s"):format(net, petId), THEME.gold)
        setStatus("turkeysighting", "Threw " .. net .. " at " .. petId)
    else
        setStatus("turkeysighting", ("%s: %s"):format(petId, tostring(why)))
    end
end)
-- AUTO RANK QUESTS -----------------------------------------------------------
-- Reads the four rank quests from your save, decides how to finish each one
-- and does it. Anything that can be done from anywhere (potions, fruit, gold
-- and rainbow machines, upgrades, gifts, diamonds) is done straight away.
-- "Best area" quests only count in your best zone; when you run the hub in
-- that world it parks you there, hatches the best egg and spawns your own
-- comets / coin jars / pinatas / lucky blocks to finish them fast. It never
-- travels to another world. Features it switches on for a quest are switched
-- back off when no quest needs them any more.
local Quest = { plans = {}, enabledByQuest = {} }
env.__PS99HUB_QUEST = Quest
do
    local QuestTypes, QuestCmds
    pcall(function() QuestTypes = require(RS.Library.Types.Quests) QuestCmds = require(RS.Library.Client.QuestCmds) end)
    local GOAL = QuestTypes and QuestTypes.Goals or {}

    local function title(goal)
        local ok, s = pcall(QuestCmds.MakeTitle, goal, true)
        return ok and s or ("Quest type " .. tostring(goal.Type))
    end
    local function bestZone()
        local ok, z = pcall(G.ZoneCmds.GetMaximumZone)
        return ok and type(z) == "table" and z or nil
    end
    local function worldNumber()
        local ok, n = pcall(function() return require(RS.Library.Util.WorldsUtil).GetWorldNumber() end)
        return ok and n or nil
    end
    local function inBestWorld()
        local z = bestZone()
        return z and not inInstance() and worldNumber() == z.WorldNumber
    end
    local function bestEggId()
        local z = bestZone()
        local fromZone = F.areaEgg(z)
        if fromZone then return fromZone end
        local sv = save()
        for id, d in pairs(G.Directory.Eggs) do
            if d.eggNumber == sv.MaximumAvailableEgg and not d.isCustomEgg then return id end
        end
    end
    -- want(key): make sure a hub feature is running for a quest
    local wanted = {}
    local function want(key)
        wanted[key] = true
        local h = UI.handles and UI.handles[key]
        if h and not h.get() then
            Quest.enabledByQuest[key] = true
            h.set(true, true)
        end
    end
    local function itemsWhere(pred)
        local out = {}
        for _, item in pairs(inventoryItems()) do
            local ok, keep = pcall(pred, item)
            if ok and keep then out[#out + 1] = item end
        end
        return out
    end
    local function classOf(item)
        local ok, c = pcall(function() return item.__class or (item:IsA("Potion") and "Potion") or (item:IsA("Fruit") and "Fruit") or (item:IsA("Pet") and "Pet") end)
        return ok and c or nil
    end
    local function tierOf(item) local ok, t = pcall(function() return item:GetTier() end) return ok and t or 1 end

    -- stand on the best zone (only ever inside the world you are already in)
    local lastPark = 0
    local function zoneLabel(z) return z and (z.ZoneName or z._id) or nil end
    -- the area's floor: Map<world>/"<n> | <name>"/INTERACT/BREAK_ZONES/BREAK_ZONE
    local function areaSlab(z)
        for _, map in ipairs(workspace:GetChildren()) do
            if map:IsA("Folder") and map.Name:match("^Map%d*$") then
                local folder
                local want = tostring(z.ZoneName or z._id)
                for _, f in ipairs(map:GetChildren()) do
                    if f.Name:sub(-#want) == want and tonumber(f.Name:match("^(%d+)")) == z.ZoneNumber then folder = f break end
                end
                local zones = folder and folder:FindFirstChild("INTERACT") and folder.INTERACT:FindFirstChild("BREAK_ZONES")
                if zones then
                    local biggest
                    for _, part in ipairs(zones:GetChildren()) do
                        if part:IsA("BasePart") and (not biggest or part.Size.X * part.Size.Z > biggest.Size.X * biggest.Size.Z) then biggest = part end
                    end
                    if biggest then return biggest end
                end
            end
        end
        return nil
    end
    local function parkInBestZone()
        local z = bestZone()
        local name = zoneLabel(z)
        if not name then return false end
        -- same as the tycoon: the point of the area's floor closest to its
        -- egg, a few studs in from the edge, facing the egg
        local slab = areaSlab(z)
        local root = hrp()
        if slab and root then
            local top = slab.Size.Y / 2 + 3
            local spot, face = slab.CFrame * CFrame.new(0, top, 0), nil
            local eggPos = F.eggPosition(bestEggId() or "")
            if eggPos then
                local margin = 4
                local rel = slab.CFrame:PointToObjectSpace(eggPos)
                local hx, hz = math.max(0, slab.Size.X / 2 - margin), math.max(0, slab.Size.Z / 2 - margin)
                -- start at the point of the coin area closest to the egg, then
                -- walk toward the middle of the area as far as possible while
                -- the egg stays within hatch range (~27 studs) - pets only roam
                -- ~55 studs from you, so the deeper in, the more of the area
                -- they cover. Without Auto Hatch, stand in the middle.
                local lx, lz = math.clamp(rel.X, -hx, hx), math.clamp(rel.Z, -hz, hz)
                if S.on.hatch then
                    local function eggDist(x, zz) return math.sqrt((x - rel.X) ^ 2 + (zz - rel.Z) ^ 2) end
                    local lo, hi = 0, 1
                    for _ = 1, 14 do
                        local mid = (lo + hi) / 2
                        if eggDist(lx * (1 - mid), lz * (1 - mid)) <= 27 then lo = mid else hi = mid end
                    end
                    lx, lz = lx * (1 - lo), lz * (1 - lo)
                else
                    lx, lz = 0, 0
                end
                local p = slab.CFrame:PointToWorldSpace(Vector3.new(lx, top, lz))
                face = Vector3.new(eggPos.X, p.Y, eggPos.Z)
                spot = (face - p).Magnitude > 0.5 and CFrame.lookAt(p, face) or CFrame.new(p)
            end
            Quest.parkSpot = spot.Position
            if not moving and (root.Position - spot.Position).Magnitude > 6 and os.clock() - lastPark > 1.5 then
                lastPark = os.clock()
                root.AssemblyLinearVelocity = Vector3.zero
                root.CFrame = spot
            end
            return true
        end
        -- the zone's own breakables say where it is, whatever the map is called
        local sum, n, points = Vector3.zero, 0, {}
        for _, b in ipairs(G.THINGS.Breakables:GetChildren()) do
            if b:IsA("Model") and b:GetAttribute("ParentID") == name then
                local ok, pos = pcall(function() return b:GetPivot().Position end)
                if ok then sum += pos n += 1 points[#points + 1] = pos end
            end
        end
        local root = hrp()
        if n > 0 and root then
            local centre = sum / n
            -- stay INSIDE the area (pets only farm the area you stand in), on
            -- the spot of the area closest to its egg: the area's breakable
            -- nearest the egg, nudged a little toward it
            local spot, face = centre + Vector3.new(0, 6, 0), nil
            local eggPos = F.eggPosition(bestEggId() or "")
            if eggPos then
                local near, nearD
                for _, pt in ipairs(points) do
                    local d = (Vector3.new(pt.X, 0, pt.Z) - Vector3.new(eggPos.X, 0, eggPos.Z)).Magnitude
                    if not nearD or d < nearD then near, nearD = pt, d end
                end
                if near then
                    local flat = Vector3.new(eggPos.X - near.X, 0, eggPos.Z - near.Z)
                    local step = flat.Magnitude > 0.1 and flat.Unit * math.min(4, flat.Magnitude * 0.25) or Vector3.zero
                    spot = near + step + Vector3.new(0, 5, 0)
                    face = Vector3.new(eggPos.X, spot.Y, eggPos.Z)
                end
            end
            Quest.parkSpot = spot
            if not moving and (root.Position - spot).Magnitude > 12 and os.clock() - lastPark > 1.5 then
                lastPark = os.clock()
                root.AssemblyLinearVelocity = Vector3.zero
                root.CFrame = face and CFrame.lookAt(spot, face) or CFrame.new(spot)
            end
            return true
        end
        local map = workspace:FindFirstChild("Map") or workspace:FindFirstChild("Map" .. tostring(worldNumber() or ""))
        if not (z and map) then return false end
        local folder
        for _, f in ipairs(map:GetChildren()) do
            if f.Name:find(z.ZoneName or z._id or "", 1, true) and (tostring(z.ZoneNumber) == f.Name:match("^(%d+)")) then folder = f break end
        end
        if not folder then
            for _, f in ipairs(map:GetChildren()) do if f.Name:find(tostring(z._id), 1, true) then folder = f break end end
        end
        if not folder then return false end
        local part
        for _, d in ipairs(folder:GetDescendants()) do
            if d:IsA("BasePart") and (d.Name == "BREAK_ZONE" or d.Parent.Name == "BREAK_ZONES" or d.Name:find("Break")) then part = d break end
        end
        part = part or (folder:FindFirstChild("PERSISTENT", true) and folder.PERSISTENT:FindFirstChild("Teleport"))
        if not part then return false end
        local root = hrp()
        if root and not moving and (root.Position - part.Position).Magnitude > 60 and os.clock() - lastPark > 1.5 then
            lastPark = os.clock()
            root.CFrame = CFrame.new(part.Position + Vector3.new(0, 5, 0))
        end
        return true
    end
    local function standAtEgg(eggId)
        -- the best area's egg is hatched from inside the area, on the edge
        -- nearest it; never step out of the area onto the egg
        if eggId and eggId == bestEggId() and inBestWorld() then
            F.unlockEgg(eggId)
            return parkInBestZone()
        end
        local pos = eggId and F.eggPosition(eggId)
        local root = hrp()
        if not (pos and root) then return false end
        if not moving and (root.Position - pos).Magnitude > 20 and os.clock() - lastPark > 1.5 then
            lastPark = os.clock()
            root.CFrame = CFrame.new(pos + Vector3.new(0, 3, 8), pos)
        end
        return true
    end

    Quest.bestZone, Quest.inBestWorld, Quest.parkInBestZone = bestZone, inBestWorld, parkInBestZone

    -- one action per quest type; returns the line shown under that quest
    local handlers = {}
    local function useItems(goal, pred, consume, noun)
        local left = goal.Amount - goal.Progress
        local items = itemsWhere(pred)
        table.sort(items, function(a, b) return tierOf(a) < tierOf(b) end)
        local used = 0
        for _, item in ipairs(items) do
            if used >= left then break end
            local n = math.min(left - used, item:GetAmount(), 10)
            if pcall(consume, item, n) then used += n end
            task.wait(0.4)
        end
        return used > 0 and ("Used %d %s"):format(used, noun) or ("No %s left to use"):format(noun)
    end
    handlers[GOAL.USE_POTION or -100] = function(goal)
        return useItems(goal, function(i)
            if classOf(i) ~= "Potion" then return false end
            if goal.PotionID and i:GetId() ~= goal.PotionID then return false end
            if goal.PotionTier and tierOf(i) ~= goal.PotionTier then return false end
            return true
        end, function(i, n) return G.PotionCmds.Consume(i:GetUID(), n) end, "potions")
    end
    handlers[GOAL.USE_FRUIT or -101] = function(goal)
        return useItems(goal, function(i)
            return classOf(i) == "Fruit" and (not goal.FruitID or i:GetId() == goal.FruitID)
        end, function(i, n) return G.FruitCmds.Consume(i:GetUID(), n) end, "fruit")
    end
    handlers[GOAL.USE_FLAG or -102] = function(goal)
        if inInstance() then return "Flags only work in a main-world zone" end
        return useItems(goal, function(i) return tostring(i:GetId()):find("Flag$") ~= nil end,
            function(i, n) return G.FlexibleFlagCmds.Consume(i:GetId(), i:GetUID(), 1) end, "flags")
    end
    local function upgrade(goal, kind)
        local remote = kind == "Potion" and "UpgradePotionsMachine_Activate" or "UpgradeEnchantsMachine_Activate"
        local machine = kind == "Potion" and "UpgradePotionsMachine" or "UpgradeEnchantsMachine"
        local wantTier = goal.PotionTier or goal.EnchantTier
        local id = goal.PotionID or goal.EnchantID
        local items = itemsWhere(function(i)
            local ok, isKind = pcall(function() return i:IsA(kind) end)
            if not (ok and isKind) then return false end
            if id and i:GetId() ~= id then return false end
            if wantTier and tierOf(i) ~= wantTier - 1 then return false end
            return i:GetAmount() >= 3
        end)
        table.sort(items, function(a, b) return tierOf(a) < tierOf(b) end)
        local item = items[1]
        if not item then return ("Not enough %ss to upgrade"):format(kind:lower()) end
        local n = math.min(goal.Amount - goal.Progress, math.floor(item:GetAmount() / 3))
        local uid = item:GetUID()
        local ok, msg = invoke(remote, uid, n)
        if not ok and tostring(msg):lower():find("far") and not inInstance() then
            local map = workspace:FindFirstChild("Map")
            local pad
            for _, d in ipairs(map and map:GetDescendants() or {}) do
                if d.Name == machine and d:IsA("Model") then pad = d:FindFirstChild("Pad") or d:FindFirstChildWhichIsA("BasePart", true) break end
            end
            if pad then
                withTeleport(function(root)
                    root.CFrame = CFrame.new(pad.Position + Vector3.new(0, 4, 0))
                    task.wait(0.8)
                    ok, msg = invoke(remote, uid, n)
                end)
            end
        end
        return ok and ("Upgraded %d %s"):format(n, item:GetId()) or ("Upgrade refused: " .. tostring(msg))
    end
    handlers[GOAL.UPGRADE_POTION or -103] = function(goal) return upgrade(goal, "Potion") end
    handlers[GOAL.UPGRADE_ENCHANT or -104] = function(goal) return upgrade(goal, "Enchant") end
    local function machinePets(goal, wantPt, remote, fromBestEgg)
        local bestSet
        if fromBestEgg then
            local egg = dirGet("Eggs", bestEggId() or "")
            bestSet = {}
            for _, p in ipairs(egg and egg.pets or {}) do bestSet[p[1]] = true end
        end
        local left = goal.Amount - goal.Progress
        local pick
        for uid, pet in pairs(save().Inventory.Pet or {}) do
            if pet.pt == wantPt and not pet.sh and (pet._am or 1) >= 10 and not pet._lk
                and (not bestSet or bestSet[pet.id]) and not (Chances.petInfo(pet.id) or {}).huge then
                if not pick or (pet._am or 1) > pick.amount then pick = { uid = uid, id = pet.id, amount = pet._am or 1 } end
            end
        end
        if not pick then
            return fromBestEgg and "Need 10 of one pet from your best egg (hatch more of it)" or "Need 10 of one pet"
        end
        local batches = math.min(left, math.floor(pick.amount / 10))
        local ok, msg = invoke(remote, pick.uid, batches)
        return ok and ("Made %d from %s"):format(batches, pick.id) or ("Machine refused: " .. tostring(msg))
    end
    handlers[GOAL.GOLD_PET or -105] = function(goal) return machinePets(goal, nil, "GoldMachine_Activate", false) end
    handlers[GOAL.RAINBOW_PET or -106] = function(goal) return machinePets(goal, 1, "RainbowMachine_Activate", false) end
    handlers[GOAL.BEST_GOLD_PET or -107] = function(goal)
        if GOAL.BEST_EGG and inBestWorld() then want("hatch") standAtEgg(bestEggId()) end
        return machinePets(goal, nil, "GoldMachine_Activate", true)
    end
    handlers[GOAL.BEST_RAINBOW_PET or -108] = function(goal)
        return machinePets(goal, 1, "RainbowMachine_Activate", true)
    end
    -- collected from breakables, gifts and lootboxes: farm + open everything
    local function farmFor(goal, extra)
        if Tycoon.plot() then
            if S.on.tycoonfarm then return "Farming the tycoon (main-world drops count here only in the main world)" end
        end
        if not inInstance() then want("farm") end
        want("giftbags")
        if extra then extra() end
        return inInstance() and "Opening gift bags (farm counts in the main world)" or "Farming breakables + opening gift bags"
    end
    for _, name in ipairs({ "COLLECT_POTION", "COLLECT_ENCHANT", "COLLECT_FRUIT", "COLLECT_LOOTBAG", "CURRENCY", "OBTAIN_CURRENCY",
        "BREAKABLE", "DIAMOND_BREAKABLE", "MINI_CHEST" }) do
        if GOAL[name] then handlers[GOAL[name]] = function(goal) return farmFor(goal) end end
    end
    if GOAL.DIAMOND_BREAKABLE then handlers[GOAL.DIAMOND_BREAKABLE] = function(goal)
        if inInstance() then return "Diamond piles are in the main world" end
        want("farm")
        table.insert(Quest.focus, "Diamond")
        if inBestWorld() then
            parkInBestZone()
            Quest.zoneLock = zoneLabel(bestZone())
        end
        return "Farming with every pet on diamond piles"
    end end
    if GOAL.FREE_GIFT then handlers[GOAL.FREE_GIFT] = function() want("freegifts") return "Claiming free gifts as they unlock" end end
    if GOAL.ZONE then handlers[GOAL.ZONE] = function() if inInstance() then return "Zones are bought in the main world" end want("zones") return "Buying the next zone when affordable" end end
    -- hatching
    local function hatchQuest(goal, eggId)
        want("hatch")
        if eggId and not inInstance() then
            if standAtEgg(eggId) then return "Hatching " .. eggId end
            return ("%s is not in this world"):format(eggId)
        end
        return "Hatching the egg you are next to"
    end
    if GOAL.EGG then handlers[GOAL.EGG] = function(goal) return hatchQuest(goal, goal.EggID) end end
    if GOAL.PET then handlers[GOAL.PET] = function(goal) return hatchQuest(goal, nil) end end
    if GOAL.HATCH_RARE_PET then handlers[GOAL.HATCH_RARE_PET] = function(goal)
        if inBestWorld() then return hatchQuest(goal, bestEggId()) end
        return hatchQuest(goal, nil)
    end end
    if GOAL.BEST_EGG then handlers[GOAL.BEST_EGG] = function(goal)
        if not inBestWorld() then return nil end
        return hatchQuest(goal, bestEggId())
    end end
    -- best area: break things there, spawning your own event items to speed it up
    -- Lua patterns, anchored, so "Comet" never matches "Comet Cyclops Ball"
    local SPAWNERS = {
        BEST_COMET = { "^Comet$", "Comet_Spawn" }, COMET = { "^Comet$", "Comet_Spawn" },
        BEST_COIN_JAR = { "^%a+ Coin Jar$", "CoinJar_Spawn" }, COIN_JAR = { "^%a+ Coin Jar$", "CoinJar_Spawn" },
        BEST_PINATA = { "^Mini Pinata$", "MiniPinata_Consume" }, PINATA = { "^Mini Pinata$", "MiniPinata_Consume" },
        BEST_LUCKYBLOCK = { "^Mini Lucky Block$", "MiniLuckyBlock_Consume" }, LUCKYBLOCK = { "^Mini Lucky Block$", "MiniLuckyBlock_Consume" },
    }
    -- spawn one of your own event items where you stand. Returns
    -- (spawned, itemName, reason): reason "busy" = the area already has an
    -- event going (the game allows one at a time), "none" = you have none
    local lastTry, busyUntil, lastNote = {}, {}, {}
    local function spawnOwn(kind)
        local spec = SPAWNERS[kind]
        if not spec then return false, nil, "none" end
        local item, id
        for _, it in pairs(inventoryItems()) do
            local iid = itemId(it)
            if iid and iid:match(spec[1]) then item, id = it, iid break end
        end
        if not item then return false, nil, "none" end
        if os.clock() < (busyUntil[kind] or 0) then return false, id, "busy" end
        if os.clock() - (lastTry[kind] or 0) < 3 then return false, id, lastNote[kind] or "wait" end
        lastTry[kind] = os.clock()
        local ok, msg = invoke(spec[2], item:GetUID())
        if ok then
            lastNote[kind] = "spawned"
            busyUntil[kind] = os.clock() + 4
            invAt = 0
            return true, id
        end
        if tostring(msg):lower():find("already") then
            busyUntil[kind] = os.clock() + 6
            lastNote[kind] = "busy"
            return false, id, "busy"
        end
        lastNote[kind] = tostring(msg)
        return false, id, tostring(msg)
    end
    Quest.spawnOwn = spawnOwn
    local FOCUS = {
        BEST_MINI_CHEST = { "Mini Chest" }, BEST_SUPERIOR_MINI_CHEST = { "Superior Mini Chest" },
        BEST_COMET = { "Comet" }, BEST_COIN_JAR = { "Coin Jar" }, BEST_PINATA = { "Pinata", "Piñata" },
        BEST_LUCKYBLOCK = { "Lucky Block", "LuckyBlock" },
    }
    for _, name in ipairs({ "CURRENT_BREAKABLE", "BEST_MINI_CHEST", "BEST_SUPERIOR_MINI_CHEST", "BEST_COMET", "BEST_COIN_JAR", "BEST_PINATA", "BEST_LUCKYBLOCK" }) do
        if GOAL[name] then handlers[GOAL[name]] = function(goal)
            if not inBestWorld() then return nil end
            local bz = bestZone()
            local areaEgg = F.areaEgg(bz)
            if areaEgg then F.unlockEgg(areaEgg) end
            parkInBestZone()
            want("farm")
            Quest.zoneLock = zoneLabel(bz)
            -- a comet or coin jar drops a pile of extra breakables right in the
            -- best area: the fastest way through "break N breakables" quests
            if name == "CURRENT_BREAKABLE" then
                -- comets / coin jars don't speed up plain breakable quests, so
                -- they are only ever used for their own quests
                return "Farming the best area"
            end
            if FOCUS[name] then
                for _, w in ipairs(FOCUS[name]) do table.insert(Quest.focus, w) end
            end
            if SPAWNERS[name] and S.on.questitems ~= false then
                local spawned, what, why = spawnOwn(name)
                if spawned then return ("Used your %s - pets are on it"):format(what) end
                if why == "busy" then return ("Breaking the %s already in the area, then using the next one"):format(what or "event") end
                if why == "none" then return "None of these in your inventory - breaking random ones when they show up" end
                if why == "spawned" or why == "wait" then return ("Pets are breaking your %s"):format(what or "item") end
                return ("Can't use %s here: %s"):format(tostring(what), tostring(why))
            end
            return "Farming the best area"
        end end
    end
    for _, name in ipairs({ "COMET", "COIN_JAR", "PINATA", "LUCKYBLOCK" }) do
        if GOAL[name] then handlers[GOAL[name]] = function(goal)
            if inInstance() then return "Needs a main-world zone" end
            want("farm")
            local spawned, what = spawnOwn(name)
            return spawned and ("Spawned your " .. what) or "Farming (spawns your own when available)"
        end end
    end

    loop("autoquest", 1, function()
        local goals = save().Goals
        if type(goals) ~= "table" then return setStatus("autoquest", "No rank quests found") end
        table.clear(wanted)
        Quest.zoneLock, Quest.focus = nil, {}
        -- which quest types are still open (used to share the area's event slot)
        Quest.types = {}
        for _, g in pairs(goals) do
            if (g.Progress or 0) < (g.Amount or 1) then Quest.types[g.Type] = true end
        end
        local plans, done, blocked = {}, 0, 0
        local bz = bestZone()
        local slots = {}
        for slot in pairs(goals) do slots[#slots + 1] = slot end
        table.sort(slots, function(a, b) return tostring(a) < tostring(b) end)
        local list = {}
        for _, slot in ipairs(slots) do list[#list + 1] = { goal = goals[slot] } end
        -- the Item Creator's quest is worked on like a fifth rank quest
        local ic = save().ItemCreator
        if S.on.itemcreator and type(ic) == "table" and type(ic.Goal) == "table" and not ic.GoalCompleted then
            list[#list + 1] = { goal = ic.Goal, prefix = "Item Creator: " }
            if (ic.Goal.Progress or 0) < (ic.Goal.Amount or 1) then Quest.types[ic.Goal.Type] = true end
        end
        for _, entry in ipairs(list) do
            local goal = entry.goal
            local plan = { title = (entry.prefix or "") .. title(goal), progress = goal.Progress or 0, amount = goal.Amount or 1, stars = goal.Stars }
            if (goal.Progress or 0) >= (goal.Amount or 1) then
                plan.text, plan.state = "Done - waiting for the game to hand out the next one", "done"
                done += 1
            else
                local h = handlers[goal.Type]
                local okH, text = false, nil
                if h then okH, text = pcall(h, goal) end
                if not h then
                    plan.text, plan.state = "This quest type can't be automated (do it by hand)", "manual"
                    blocked += 1
                elseif not okH then
                    plan.text, plan.state = "Error: " .. tostring(text):sub(1, 80), "error"
                elseif text == nil then
                    plan.text = ("Only counts in your best area (%s). Run the hub in that world."):format(bz and (bz.ZoneName or bz._id) or "best zone")
                    plan.state = "blocked"
                    blocked += 1
                else
                    plan.text, plan.state = text, "working"
                end
            end
            plans[#plans + 1] = plan
        end
        Quest.plans = plans
        S.farmZone = Quest.zoneLock
        S.farmFocus = #Quest.focus > 0 and Quest.focus or nil
        -- hand back anything a quest switched on that no quest wants now
        -- (only after no quest has wanted it for 10s, so quests rotating or a
        -- one-tick hiccup never flicker the farm off and on)
        Quest.unwantedSince = Quest.unwantedSince or {}
        for key in pairs(Quest.enabledByQuest) do
            if wanted[key] then
                Quest.unwantedSince[key] = nil
            else
                Quest.unwantedSince[key] = Quest.unwantedSince[key] or os.clock()
                if os.clock() - Quest.unwantedSince[key] > 10 then
                    Quest.enabledByQuest[key] = nil
                    Quest.unwantedSince[key] = nil
                    local h = UI.handles and UI.handles[key]
                    if h and h.get() then h.set(false, true) end
                end
            end
        end
        setStatus("autoquest", ("%d/%d done  ·  %d need the best area or your hands  ·  rank %s, %s stars"):format(done, #plans, blocked, tostring(save().Rank), tostring(save().RankStars)))
    end)
    -- turning auto quests off gives back what it switched on
    function Quest.release()
        S.farmZone, S.farmFocus, S.farmFocusPoints = nil, nil, nil
        for key in pairs(Quest.enabledByQuest) do
            local h = UI.handles and UI.handles[key]
            if h and h.get() then h.set(false, true) end
        end
        table.clear(Quest.enabledByQuest)
    end
end
-- AUTO AREA FARM -------------------------------------------------------------
-- Buys every zone you can afford, stands you in your best (newest) area the
-- way Auto Rank Quests does, and keeps Fast Farm working that whole area.
-- Stays in the world you're in: it never travels between worlds.
local AreaFarm = { enabledFarm = false }
function AreaFarm.release()
    S.areaFarmZone = nil
    if AreaFarm.enabledFarm then
        AreaFarm.enabledFarm = false
        local h = UI.handles and UI.handles.farm
        if h and h.get() then h.set(false, true) end
    end
end
loop("areafarm", 1, function()
    if inInstance() or not G.ZoneCmds then
        S.areaFarmZone = nil
        return setStatus("areafarm", "Main world only - on the event island use Tycoon Zone Farm")
    end
    local bought, why = F.buyNextZones("areafarm")
    local z = Quest.bestZone and Quest.bestZone()
    if not z then return setStatus("areafarm", "Couldn't read your best area yet") end
    local name = tostring(z.ZoneName or z._id)
    if not Quest.inBestWorld() then
        S.areaFarmZone = nil
        return setStatus("areafarm", ("Your best area (%s) is in world %s - go there and it takes over"):format(name, tostring(z.WorldNumber)))
    end
    S.areaFarmZone = name
    local h = UI.handles and UI.handles.farm
    if h and not h.get() then
        AreaFarm.enabledFarm = true
        h.set(true, true)
    end
    local parked = Quest.parkInBestZone()
    local head = #bought > 0 and ("Bought " .. table.concat(bought, ", ") .. "  ·  ") or ""
    setStatus("areafarm", ("%sFarming %s%s%s"):format(head, name, parked and "" or " (couldn't find its floor)", why and ("  ·  " .. why) or ""))
end)
-- AUTO PICKUP ----------------------------------------------------------------
-- Coins, diamonds, lootbags and every other drop are "orbs" that the game's
-- own magnet collects within Orb.DefaultPickupDistance (20) + Magnet. Pets
-- break things far from you, so loot lands out of reach; widening that range
-- lets the game's normal pickup grab all of it.
do
    local OrbMod
    pcall(function() OrbMod = require(RS.Library.Client.OrbCmds.Orb) end)
    local original = OrbMod and OrbMod.DefaultPickupDistance or 20
    -- instant pickup: lootbags normally sit 1.5-2.5s (coins up to 0.65s)
    -- before the magnet takes them; drop that wait and let them fly in from
    -- anywhere (the game's own super magnet). 2.06s -> 0.55s average.
    if OrbMod and not env.__PS99HUB_ORB_NEW then
        env.__PS99HUB_ORB_NEW = OrbMod.new
        OrbMod.new = function(...)
            local o = env.__PS99HUB_ORB_NEW(...)
            if type(o) == "table" and S.on.autopickup and S.on.instantpickup ~= false then
                o._pickupDelay = 0
                o._superMagnet = true
            end
            return o
        end
    end
    task.spawn(function()
        while alive() do
            if OrbMod then
                local want = S.on.autopickup and (tonumber(Settings.values.pickupRange) or 250) or original
                if OrbMod.DefaultPickupDistance ~= want then OrbMod.DefaultPickupDistance = want end
                if S.on.autopickup then
                    setStatus("autopickup", ("Collecting every drop within %d studs"):format(want))
                end
            else
                setStatus("autopickup", "Pickup module not found")
            end
            task.wait(1)
        end
        if OrbMod then OrbMod.DefaultPickupDistance = original end
    end)
end

-- LAST AREA EGG ----------------------------------------------------------------
-- Separate from Auto Hatch: waits until your island reaches its LAST area
-- (Golden Ridge), then hatches only that area's egg - never any other egg.
-- Same speed tricks as Auto Hatch (server-cooldown pacing, no animation).
do
    local running = false
    local function lastEgg()
        local plot, _, m = Tycoon.plot()
        if not plot then return nil, "Join the Pumpkin Tycoon to use this" end
        local zones = m.Types.ZONES
        local last = zones[#zones]
        local idx = Tycoon.bestZone()
        if not idx or idx < #zones then
            return nil, ("Waiting for the last area (%s)  ·  you're on area %s of %d"):format(tostring(last.DisplayName), tostring(idx or "?"), #zones)
        end
        local egg
        pcall(function()
            for _, e in pairs(G.CustomEggsCmds.All()) do if e._id == last.Egg then egg = e break end end
        end)
        if not egg then return nil, last.Egg .. " isn't loaded yet" end
        return egg, last
    end
    function F.startLastHatch()
        if running then return end
        running = true
        task.spawn(function()
            local hatched = 0
            while S.on.lasthatch and alive() do
                if S.on.hatch then
                    S.lastHatching = false
                    setStatus("lasthatch", "Auto Hatch is on and already hatching - this waits")
                    task.wait(1)
                else
                    local egg, info = lastEgg()
                    if not egg then
                        S.lastHatching = false
                        setStatus("lasthatch", info)
                        task.wait(2)
                    else
                        S.lastHatching = true
                        local dir = egg._dir or dirGet("Eggs", egg._id)
                        local max = egg._maxEggCount or select(2, pcall(G.EggCmds.GetMaxHatch, dir)) or 1
                        local amount = tonumber(max) or 1
                        local price = dir and (dir.overrideCost or dir.cost)
                        if dir and dir.currency and type(price) == "number" and price > 0 then
                            local okC, have = pcall(G.CurrencyCmds.Get, dir.currency)
                            if okC and type(have) == "number" then amount = math.min(amount, math.floor(have / price)) end
                        end
                        amount = math.max(0, math.floor(amount / (S.lastShrink or 1)))
                        if amount < 1 then
                            setStatus("lasthatch", ("Saving Patch Coins for %s"):format(egg._id))
                            task.wait(1)
                        else
                            local okD, cooldown = pcall(G.EggCmds.ComputeDebounce)
                            cooldown = okD and tonumber(cooldown) or 2.5
                            S.lastLead = S.lastLead or 0.35
                            local readyAt = (S.lastHatchAt or 0) + cooldown - S.lastLead
                            while os.clock() < readyAt and S.on.lasthatch do task.wait(0.02) end
                            local tries, done = 0, false
                            while not done and S.on.lasthatch and alive() do
                                tries += 1
                                if G.Variables.OpeningEgg < 1 then G.Variables.OpeningEgg = 1 end
                                local sentAt = os.clock()
                                local okH, success, err = pcall(G.Network.Invoke, "CustomEggs_Hatch", egg._uid, amount)
                                if okH and success then
                                    S.lastHatchAt = sentAt + (os.clock() - sentAt) / 2
                                    S.lastShrink = 1
                                    hatched += amount
                                    S.eggs += amount
                                    if tries == 1 then S.lastLead = math.min(cooldown * 0.9, S.lastLead + 0.04)
                                    elseif tries > 4 then S.lastLead = math.max(0, S.lastLead - 0.04) end
                                    setStatus("lasthatch", ("Hatching %s  ·  %d per hatch  ·  %s this session"):format(egg._id, amount, commas(hatched)))
                                    done = true
                                else
                                    local raw = tostring(okH and (err or success) or success)
                                    if raw:lower():find("enough") or raw:lower():find("coins") or raw:lower():find("afford") then
                                        S.lastShrink = math.min((S.lastShrink or 1) * 2, 64)
                                        done = true
                                    elseif tries >= 70 then
                                        setStatus("lasthatch", egg._id .. ": " .. raw:sub(1, 60))
                                        done = true
                                    else
                                        task.wait(0.06)
                                    end
                                end
                            end
                        end
                    end
                end
            end
            S.lastHatching = false
            if not S.on.hatch then pcall(function() G.Variables.OpeningEgg = 0 end) end
            running = false
        end)
    end
end

-- TYCOON REBIRTH -------------------------------------------------------------------
-- Rebirths the island when it's 100% built, but only while a rebirth still
-- raises Huge or Titanic odds (the game says "maxed" once it doesn't).
local TycoonRebirth = {}
do
    local function mods()
        local ok, m = pcall(function()
            return {
                R = require(RS.Library.Client.PumpkinTycoonCmds.Rebirth),
                PT = require(RS.Library.Types.PumpkinTycoon),
                PTB = require(RS.Library.Util.PumpkinTycoonButtons),
                B = require(RS.Library.Types.PumpkinTycoon.Buttons),
            }
        end)
        return ok and m or nil
    end
    -- what the next rebirth gives, straight from the game's own texts
    function TycoonRebirth.info()
        local plot = Tycoon.plot()
        local m = mods()
        if not (plot and m) then return nil end
        local n = select(2, pcall(m.R.Rebirths, plot)) or 0
        local okR, rows = pcall(m.R.RowTexts, n)
        local state
        pcall(function() state = plot:Save(m.PT.VAR.Buttons) end)
        local okP, have, need, frac = pcall(m.PTB.RebirthProgress, state)
        local huge = okR and rows.huge or "?"
        local titanic = okR and rows.titanic or "?"
        local maxed = tostring(huge):find("maxed") ~= nil and tostring(titanic):find("maxed") ~= nil
        return {
            rebirths = n, rows = okR and rows or {}, maxed = maxed,
            ready = select(2, pcall(m.PTB.RebirthReady, state)) == true,
            progress = okP and frac or 0, have = okP and have or 0, need = okP and need or 0,
            plot = plot, m = m,
        }
    end
    loop("tycoonrebirth", 3, function()
        local info = TycoonRebirth.info()
        if not info then return setStatus("tycoonrebirth", "Join the Pumpkin Tycoon to use this") end
        if info.maxed then
            return setStatus("tycoonrebirth", ("Huge and Titanic odds are maxed at rebirth %d  ·  not rebirthing"):format(info.rebirths))
        end
        if not info.ready then
            return setStatus("tycoonrebirth", ("Island %d%% built (%d/%d)  ·  rebirths at 100%%"):format(math.floor(info.progress * 100), info.have, info.need))
        end
        local plot, m = info.plot, info.m
        local function try() return pcall(function() return plot:Invoke(m.B.VERB_REBIRTH) end) end
        local okC, ok, reason = try()
        if not (okC and ok) then
            -- some servers want you at the rebirth shrine: hop there and back
            local _, model = Tycoon.plot()
            local shrine = model and model:FindFirstChild(m.PT.REBIRTH_SHRINE, true)
            if shrine then
                withTeleport(function(root)
                    local pos = shrine:GetPivot().Position
                    root.CFrame = CFrame.new(pos + Vector3.new(0, 4, 8), pos)
                    task.wait(0.8)
                    okC, ok, reason = try()
                end)
            end
        end
        if okC and ok then
            UI.toast("TYCOON REBIRTH", ("Rebirth %d done - next: %s"):format(info.rebirths + 1, tostring(info.rows.huge)), THEME.gold)
            setStatus("tycoonrebirth", ("Rebirthed to %d"):format(info.rebirths + 1))
            -- the island starts over: farm and pets go back to the first area
            Tycoon.retarget = true
            Tycoon.moveToNewArea = true
        else
            setStatus("tycoonrebirth", "Rebirth refused: " .. tostring(reason or ok))
        end
    end)
end

-- AFK SAVER --------------------------------------------------------------------
-- While the hub is hidden: 3D rendering off and an FPS cap, so a long AFK
-- farm barely touches your GPU/CPU. Everything comes back when you open
-- the hub, turn this off or unload.
do
    local RunS = game:GetService("RunService")
    local applied = false
    local function apply(on)
        if on == applied then return end
        applied = on
        pcall(function() RunS:Set3dRenderingEnabled(not on) end)
        pcall(function() setfpscap(on and (tonumber(Settings.values.afkFps) or 15) or 240) end)
    end
    F.afkApply = apply
    task.spawn(function()
        while alive() do
            local want = S.on.afksaver and not UI.win.Visible
            apply(want == true)
            if applied then setStatus("afksaver", ("Saving power  ·  3D off, %d fps cap  ·  open the hub to see the game"):format(tonumber(Settings.values.afkFps) or 15))
            elseif S.on.afksaver then setStatus("afksaver", "Kicks in when you hide the hub") end
            task.wait(0.5)
        end
        apply(false)
    end)
end

-- AUTO REJOIN ------------------------------------------------------------------
-- When Roblox shows a disconnect / kick error, rejoin the same game and run
-- the hub again (queued through the executor, read from its workspace file).
do
    local GuiService = game:GetService("GuiService")
    local TeleportService = game:GetService("TeleportService")
    local rejoining = false
    local function rejoin(reason)
        if rejoining or not S.on.autorejoin then return end
        rejoining = true
        setStatus("autorejoin", "Disconnected (" .. tostring(reason):sub(1, 40) .. ")  ·  rejoining...")
        pcall(function()
            local q = queue_on_teleport or queueonteleport or (syn and syn.queue_on_teleport)
            if q then q('repeat task.wait() until game:IsLoaded() task.wait(5) pcall(function() loadstring(readfile("ps99_hub.luau"))() end)') end
        end)
        task.wait(3)
        for _ = 1, 10 do
            pcall(function() TeleportService:Teleport(game.PlaceId, LocalPlayer) end)
            task.wait(8)
        end
        rejoining = false
    end
    -- some executor threads can't listen to GuiService; fall back to watching
    -- the disconnect prompt itself
    local hooked = pcall(function()
        GuiService.ErrorMessageChanged:Connect(function(msg)
            if msg and msg ~= "" then task.spawn(rejoin, msg) end
        end)
    end)
    if not hooked then
        task.spawn(function()
            while alive() do
                local ok, msg = pcall(function()
                    local overlay = game:GetService("CoreGui").RobloxPromptGui.promptOverlay
                    local prompt = overlay:FindFirstChild("ErrorPrompt")
                    if not prompt then return nil end
                    local label = prompt:FindFirstChild("ErrorMessage", true)
                    return label and label.Text or "disconnected"
                end)
                if ok and msg then rejoin(msg) end
                task.wait(2)
            end
        end)
    end
    task.spawn(function()
        while alive() do
            if S.on.autorejoin and not rejoining then setStatus("autorejoin", "Watching for disconnects") end
            task.wait(5)
        end
    end)
end

-- DISCORD SESSION REPORT -----------------------------------------------------------
-- Every N minutes, post a summary of the session to your webhook.
do
    local startDiamonds, startCoins, startT = nil, nil, os.clock()
    local function report()
        local url = Webhook.url and Webhook.url()
        if not url then return false, "no webhook set" end
        local sv = save()
        local gems = diamonds()
        startDiamonds = startDiamonds or gems
        local mins = math.max(1, math.floor((os.clock() - startT) / 60))
        local fields = {
            { name = "Session", value = ("%dh %02dm"):format(mins // 60, mins % 60), inline = true },
            { name = "Eggs hatched", value = ("%s  (lifetime %s)"):format(commas(S.eggs), commas(sv.EggsHatched or 0)), inline = true },
            { name = "Huges", value = tostring(Tracker.huges), inline = true },
            { name = "Diamonds", value = ("%s  (%s%s)"):format(short(gems), gems >= startDiamonds and "+" or "-", short(math.abs(gems - startDiamonds))), inline = true },
            { name = "Rank", value = ("%s  ·  %s stars"):format(tostring(sv.Rank), tostring(sv.RankStars)), inline = true },
        }
        local quests = {}
        for _, p in ipairs(Quest.plans or {}) do quests[#quests + 1] = ("%s: %s/%s"):format(p.title, commas(p.progress), commas(p.amount)) end
        if #quests > 0 then fields[#fields + 1] = { name = "Rank quests", value = table.concat(quests, "\n"):sub(1, 1000), inline = false } end
        local plot, _, m = Tycoon.plot()
        if plot then
            local coins = Tycoon.coins(m)
            startCoins = startCoins or coins
            fields[#fields + 1] = { name = "Tycoon", value = ("%s coins  ·  %d bought  ·  wild caught %d"):format(short(coins), S.counts.tycoon, WildStats.caught), inline = false }
        end
        local httpRequest = (syn and syn.request) or (http and http.request) or http_request or request
        if not httpRequest then return false, "no http request function" end
        local body = { username = "PS99 Hub", embeds = { {
            title = "Session report", description = ("**%s** is still farming"):format(LocalPlayer.Name),
            color = 0xFF96BE, fields = fields, footer = { text = "PS99 Hub" }, timestamp = DateTime.now():ToIsoDate(),
        } }, allowed_mentions = { parse = {} } }
        local ok, res = pcall(httpRequest, { Url = url, Method = "POST", Headers = { ["Content-Type"] = "application/json" }, Body = HttpService:JSONEncode(body) })
        local code = ok and type(res) == "table" and tonumber(res.StatusCode) or 0
        return code >= 200 and code < 300, ok and ("Discord answered " .. tostring(code)) or tostring(res)
    end
    F.sendReport = report
    local lastSent = os.clock()
    task.spawn(function()
        while alive() do
            local every = (tonumber(Settings.values.reportMinutes) or 60) * 60
            if S.on.webhookreport then
                if os.clock() - lastSent >= every then
                    lastSent = os.clock()
                    local ok, err = report()
                    setStatus("webhookreport", ok and ("Report sent  ·  next in %d min"):format(every // 60) or ("Report failed: " .. tostring(err)))
                else
                    setStatus("webhookreport", ("Next report in %d min"):format(math.ceil((every - (os.clock() - lastSent)) / 60)))
                end
            else
                lastSent = os.clock()
            end
            task.wait(5)
        end
    end)
end

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
local walkConn
walkConn = RunService.Heartbeat:Connect(function()
    -- a reload starts a new copy: drop this one instead of stacking
    if not alive() then walkConn:Disconnect() return end
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
    local hatchTab = UI.tab("Hatch", 2)
    local eventTab = UI.tab("Event", 3)
    local catchTab = UI.tab("Catching", 4)
    local s = UI.section(hatchTab, "Hatching", THEME.gold)
    UI.toggle(s, "hatch", "Auto Hatch", "Hatches the nearest egg at max amount, no animation", false, function(on) if on then F.startHatch() end end)
    UI.status(s, "hatch", "Off")
    UI.toggle(s, "lasthatch", "Hatch Last Area Egg Only", "Event island: waits for your last area, then hatches only that egg (separate from Auto Hatch)", false, function(on)
        if on then F.startLastHatch() end
    end)
    UI.status(s, "lasthatch", "Off")
    s = UI.section(farm, "Farming", THEME.good)
    UI.toggle(s, "fastpets", "Fast Pets", "Pets move x200 faster everywhere - main world, event, any area", true)
    UI.toggle(s, "autopickup", "Auto Pickup Everything", "Coins, diamonds, lootbags and all drops, from far away", true)
    UI.status(s, "autopickup", "Off")
    UI.slider(s, "pickupRange", "Pickup range (studs)", 40, 600, 250, 10)
    UI.toggle(s, "instantpickup", "Instant Pickup", "Lootbags and coins fly to you the moment they drop (no 2s wait)", true)
    UI.toggle(s, "farm", "Fast Farm", "Pets break everything within 100 studs, orbs and lootbags collected", false, function(on) if on then F.startFarm() end end)
    UI.status(s, "farm", "Off")
    UI.toggle(s, "areafarm", "Auto Area Farm", "Buys every zone you can afford, moves you into your best area and farms all of it (this world only)", false, function(on)
        if on then F.kick("areafarm") else AreaFarm.release() end
    end)
    UI.status(s, "areafarm", "Off")
    UI.toggle(s, "ultimate", "Auto Ultimate", "Fires your equipped ultimate whenever it is charged in a zone", false)
    UI.status(s, "ultimate", "Off")
    UI.toggle(s, "equipbest", "Auto Equip Best", "Re-equips your strongest pets every 30 seconds", false)
    UI.status(s, "equipbest", "Off")
    s = UI.section(eventTab, "Pumpkin Tycoon", Color3.fromRGB(255, 150, 70))
    UI.toggle(s, "tycoon", "Auto Buy Tycoon", "Buys the cheapest affordable button first, all the way through", false, function(on)
        if on and Tycoon.plot() and UI.handles.tycoonfarm then UI.handles.tycoonfarm.set(true, true) end
    end)
    UI.status(s, "tycoon", "Off")
    UI.toggle(s, "tycoonfarm", "Tycoon Zone Farm", "Farms your highest tycoon zone, moves up when a new one opens", false, function(on)
        if on then Tycoon.startFarm() end
    end)
    UI.status(s, "tycoonfarm", "Off")
    UI.toggle(s, "tycoonupgrades", "Auto Token Upgrades", "Spends Pumpkin Tokens: Faster Spawns first, then coins and spawn luck", false)
    UI.status(s, "tycoonupgrades", "Off")
    UI.toggle(s, "tycoonrebirth", "Auto Rebirth Tycoon", "Rebirths at 100% only while Huge / Titanic odds still go up", false)
    UI.status(s, "tycoonrebirth", "Off")
    do
        -- live "next rebirth gives" panel under the switch
        s.n += 1
        local panel = UI.new("Frame", { LayoutOrder = s.n, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundColor3 = THEME.panel, BackgroundTransparency = 0.55, ZIndex = 4 }, s.frame)
        UI.corner(panel, 10)
        UI.glassAdd(panel)
        UI.pad(panel, 16, 12, 8, 8)
        UI.new("UIListLayout", { Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.LayoutOrder }, panel)
        local head = UI.label(panel, { text = "NEXT REBIRTH", font = Enum.Font.GothamBold, size = 11, colour = THEME.gold, sz = UDim2.new(1, 0, 0, 16), z = 5 })
        head.LayoutOrder = 0
        local ORDER = { { "huge", "Huge Luck" }, { "titanic", "Titanic Luck" }, { "coins", "Patch Coins" }, { "net", "Pet Net Luck" }, { "turkey", "Turkey Damage" }, { "gift", "Flannel Gifts" } }
        local lines = {}
        for i, row in ipairs(ORDER) do
            local l = UI.label(panel, { text = "", size = 11, sz = UDim2.new(1, 0, 0, 15), z = 5, rich = true })
            l.LayoutOrder = i
            lines[row[1]] = l
        end
        task.spawn(function()
            while alive() do
                if eventTab.page.Visible and UI.win.Visible then
                    local info = TycoonRebirth.info()
                    if info then
                        head.Text = ("NEXT REBIRTH  ·  you're on rebirth %d%s"):format(info.rebirths, info.maxed and "  ·  Huge/Titanic maxed" or "")
                        for _, row in ipairs(ORDER) do
                            local text = info.rows[row[1]] or "-"
                            local colour = tostring(text):find("maxed") and "#9a8a94" or ((row[1] == "huge" or row[1] == "titanic") and "#ffd33d" or "#ffeef4")
                            lines[row[1]].Text = ('<font color="#cea0b6">%s:</font>  <font color="%s">%s</font>'):format(row[2], colour, tostring(text))
                        end
                    else
                        head.Text = "NEXT REBIRTH  ·  join the Pumpkin Tycoon to see it"
                        for _, l in pairs(lines) do l.Text = "" end
                    end
                end
                task.wait(3)
            end
        end)
    end

    s = UI.section(eventTab, "Event boosts & loot", THEME.good)
    UI.toggle(s, "cocoa", "Auto Hot Cocoa", "Keeps the coins, damage and luck cocoa boosts topped up", false)
    UI.status(s, "cocoa", "Off")
    UI.slider(s, "cocoaMinutes", "Cocoa minutes per top-up", 10, 120, 30, 10)
    UI.toggle(s, "eventboosts", "Auto Event Boosts", "Starts a Patch Coin / Damage / Island Luck boost from your bag when one runs out, best tier first", false)
    UI.status(s, "eventboosts", "Off")
    UI.toggle(s, "eventlootbox", "Auto Open Flannel Gifts", "The event's own lootbox (Patch Coins and boosts) - separate from Auto Open Lootboxes", false)
    UI.status(s, "eventlootbox", "Off")
    s = UI.section(eventTab, "Season pass", THEME.gold)
    UI.toggle(s, "eventpass", "Auto Season Pass", "Spends Season Tokens: opens the huge's tier, saves for the huge, then buys the rest", false)
    UI.status(s, "eventpass", "Off")
    s = UI.section(catchTab, "Turkey sightings", Color3.fromRGB(230, 120, 70))
    UI.toggle(s, "turkeysighting", "Auto Catch Turkey Sightings", "Throws a net at the rare huge+ sighting on your island (Ultra first)", false)
    UI.status(s, "turkeysighting", "Off")
    s = UI.section(catchTab, "Tycoon wild pets", Color3.fromRGB(255, 170, 90))
    UI.toggle(s, "wildcatch", "Auto Catch Wild Pets", "Scans every spawn; huges first, then only the rarest pets under your limit", false)
    UI.status(s, "wildcatch", "Off")
    UI.slider(s, "wildMax", "Only pets with catch chance at or below (%)", 5, 100, 30, 5)
    UI.toggle(s, "wildultrahuge", "Ultra Nets On Huges", "Ultra nets (x5) are used on huges and above only, never on normal pets", true)
    UI.toggle(s, "wildnew", "Prefer Pets Not Caught Yet", "Breaks ties toward pets missing from your collection", true)
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
    local eggsTab = hatchTab
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
    UI.toggle(s, "webhookreport", "Session Reports", "Posts eggs, huges, diamonds, quests and tycoon stats every N minutes", false)
    UI.status(s, "webhookreport", "Off")
    UI.slider(s, "reportMinutes", "Report every (minutes)", 10, 240, 60, 10)
    UI.button(s, "Send a session report now", function()
        local ok, err = F.sendReport()
        UI.toast("SESSION REPORT", ok and "Sent - check your channel" or ("Failed: " .. tostring(err)), ok and THEME.good or THEME.bad)
    end)
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

    -- QUESTS: rank quests with live progress and what the solver is doing
    local questTab = UI.tab("Quests", 5)
    s = UI.section(questTab, "Rank quests", THEME.gold)
    UI.toggle(s, "autoquest", "Auto Rank Quests", "Works out each rank quest and finishes it the fastest way it can", false, function(on)
        if not on then Quest.release() end
    end)
    UI.status(s, "autoquest", "Off")
    UI.toggle(s, "questitems", "Use My Quest Items", "Comets, coin jars, piñatas and lucky blocks - only for quests that ask for them", true)
    do
        local new, corner, stroke, label = UI.new, UI.corner, UI.stroke, UI.label
        local cards = {}
        local STATE_COLOUR = {
            done = Color3.fromRGB(150, 230, 170), working = THEME.accent, blocked = Color3.fromRGB(255, 190, 110),
            manual = THEME.muted, error = Color3.fromRGB(255, 120, 130),
        }
        for i = 1, 5 do
            s.n += 1
            local c = new("Frame", { LayoutOrder = s.n, Size = UDim2.new(1, 0, 0, 66), BackgroundColor3 = THEME.panel, BackgroundTransparency = 0.55, ZIndex = 4 }, s.frame)
            corner(c, 12)
            UI.glassAdd(c)
            local cs = stroke(c, THEME.stroke, 0.6)
            local stars = label(c, { text = "", font = Enum.Font.GothamBlack, size = 11, colour = THEME.gold, align = Enum.TextXAlignment.Right,
                anchor = Vector2.new(1, 0), sz = UDim2.fromOffset(120, 16), pos = UDim2.new(1, -14, 0, 9), z = 5 })
            local name = label(c, { text = "-", font = Enum.Font.GothamBold, size = 14, sz = UDim2.new(1, -150, 0, 18), pos = UDim2.fromOffset(14, 8), z = 5 })
            local plan = label(c, { text = "", size = 11, colour = THEME.muted, sz = UDim2.new(1, -28, 0, 14), pos = UDim2.fromOffset(14, 28), z = 5 })
            local track = new("Frame", { Position = UDim2.fromOffset(14, 48), Size = UDim2.new(1, -110, 0, 6), BackgroundColor3 = THEME.surface, BackgroundTransparency = 0.3, ZIndex = 5 }, c)
            corner(track, 3)
            local fill = new("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = THEME.accent, ZIndex = 6 }, track)
            corner(fill, 3)
            local count = label(c, { text = "", font = Enum.Font.GothamBlack, size = 11, align = Enum.TextXAlignment.Right,
                anchor = Vector2.new(1, 0), sz = UDim2.fromOffset(90, 14), pos = UDim2.new(1, -14, 0, 44), z = 5 })
            cards[i] = { frame = c, stroke = cs, stars = stars, name = name, plan = plan, fill = fill, count = count }
        end
        local function paint()
            local plans = Quest.plans
            if #plans == 0 then
                -- show the quests even when the solver is off
                local goals = save().Goals or {}
                local slots = {}
                for slot in pairs(goals) do slots[#slots + 1] = slot end
                table.sort(slots, function(a, b) return tostring(a) < tostring(b) end)
                plans = {}
                for _, slot in ipairs(slots) do
                    local g = goals[slot]
                    local okT, ttl = pcall(function() return require(RS.Library.Client.QuestCmds).MakeTitle(g, true) end)
                    plans[#plans + 1] = { title = okT and ttl or ("Quest " .. tostring(g.Type)), progress = g.Progress or 0, amount = g.Amount or 1, stars = g.Stars, text = "Turn on Auto Rank Quests", state = "manual" }
                end
            end
            for i, card in ipairs(cards) do
                local p = plans[i]
                card.frame.Visible = p ~= nil
                if p then
                    local colour = STATE_COLOUR[p.state] or THEME.muted
                    card.name.Text = p.title
                    card.plan.Text = p.text or ""
                    card.plan.TextColor3 = colour
                    card.stars.Text = p.stars and (("%d STAR%s"):format(p.stars, p.stars == 1 and "" or "S")) or ""
                    local frac = math.clamp(p.progress / math.max(1, p.amount), 0, 1)
                    card.fill.Size = UDim2.fromScale(frac, 1)
                    card.fill.BackgroundColor3 = colour
                    card.count.Text = ("%s / %s"):format(commas(p.progress), commas(p.amount))
                    card.stroke.Color = p.state == "done" and colour or THEME.stroke
                end
            end
        end
        task.spawn(function()
            while alive() do
                if questTab.page.Visible and UI.win.Visible then pcall(paint) end
                task.wait(1)
            end
        end)
    end

    s = UI.section(questTab, "Item Creator", THEME.accent)
    UI.toggle(s, "itemcreator", "Auto Item Creator", "Claims the item as soon as its quest is done; Auto Rank Quests works on the quest too", false)
    UI.status(s, "itemcreator", "Off")
    UI.toggle(s, "itemcreatorpick", "Auto Pick (15k diamonds)", "Picks the next item for you, huge potions first", false)
    UI.slider(s, "itemCreatorKeep", "Never go below (diamonds)", 0, 2000000, 100000, 50000)

    local rewards = UI.tab("Rewards", 6)
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
    UI.toggle(s, "spinwheelworlds", "Also Spin Tech / Void / Fantasy Wheels", "Uses those wheels' own tickets while you're in their world", false)
    UI.toggle(s, "wheeltickets", "Auto Free Wheel Tickets", "Claims every wheel's free ticket when it's ready, from anywhere", true)
    UI.status(s, "wheeltickets", "")
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
    UI.toggle(s, "cometshower", "Auto Comet Shower", "Free once a day - hops onto the button and back (World 1)", false)
    UI.status(s, "cometshower", "Off")
    UI.toggle(s, "areasurge", "Auto Area Surge", "Free every 15 minutes - hops onto the button and back (World 2)", false)
    UI.status(s, "areasurge", "Off")

    local items = UI.tab("Items", 7)
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
    UI.toggle(s, "keychests", "Auto Open Key Chests", "Uses full Crystal / Tech / Void / Fantasy / Hacker / MVP keys on their chest (hops there and back)", false)
    UI.status(s, "keychests", "")
    UI.slider(s, "keyKeep", "Keep this many of each key", 0, 100, 0, 1)
    s = UI.section(items, "Zone boosters", THEME.accent)
    UI.toggle(s, "flags", "Auto Place Flags", "Keeps every flag type up in the zone you farm", false)
    UI.status(s, "flags", "")
    UI.toggle(s, "sprinklers", "Auto Sprinkler", nil, false)
    UI.status(s, "sprinklers", "")
    UI.toggle(s, "jars", "Auto Coin Jars & Comets", nil, false)
    UI.status(s, "jars", "")
    UI.toggle(s, "tnt", "Auto TNT", nil, false)
    UI.status(s, "tnt", "")

    local pets = UI.tab("Pets", 8)
    s = UI.section(pets, "Machines", THEME.gold)
    UI.toggle(s, "golden", "Auto Golden", "Turns every 10 of a normal pet into a golden one (skips huges)", false)
    UI.status(s, "golden", "")
    UI.toggle(s, "rainbow", "Auto Rainbow", "Turns every 10 goldens into a rainbow (skips huges)", false)
    UI.status(s, "rainbow", "")

    local progress = UI.tab("Progress", 9)
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
    UI.toggle(s, "vouchers", "Auto Use Slot Vouchers", "Daycare and booth slot vouchers: each is a permanent +1 slot", false)
    UI.status(s, "vouchers", "")

    local misc = UI.tab("Misc", 10)
    s = UI.section(misc, "Player", Color3.fromRGB(140, 210, 255))
    UI.toggle(s, "afksaver", "AFK Saver", "While the hub is hidden: 3D rendering off + FPS cap (saves GPU on long farms)", false)
    UI.status(s, "afksaver", "Off")
    UI.slider(s, "afkFps", "AFK Saver FPS cap", 5, 60, 15, 5)
    UI.toggle(s, "autorejoin", "Auto Rejoin", "Rejoins and re-runs the hub if you get disconnected or kicked", false)
    UI.status(s, "autorejoin", "Off")
    UI.toggle(s, "antiafk", "Anti AFK", "Presses Space every few minutes, like the Pet Dimensions hub", true)
    UI.status(s, "antiafk", "")
    UI.slider(s, "afkMinutes", "Anti AFK every (minutes)", 1, 15, 1, 1)
    UI.toggle(s, "walkspeed", "Custom Walk Speed", nil, false)
    UI.slider(s, "walkspeedValue", "Walk speed", 16, 120, 40, 1, function(v) walkSpeed = v end)
    s = UI.section(misc, "Interface", THEME.accent)
    UI.slider(s, "glass", "Glass opacity %", 10, 200, 100, 5, function(v) UI.setGlass(v) end)
    UI.slider(s, "sceneFps", "Background animation FPS (0 = still)", 0, 60, 15, 3, function(v) UI.sceneFps = v end)
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
-- status lines: pushed the moment a feature reports (setStatus), with this
-- loop only catching switches turning off
local linesByKey = {}
for _, line in ipairs(UI.statusLines) do
    linesByKey[line.key] = linesByKey[line.key] or {}
    table.insert(linesByKey[line.key], line)
end
local GOOD, BAD = Color3.fromRGB(150, 230, 170), Color3.fromRGB(255, 140, 150)
local function paintLine(line, text)
    if line.label.Text == text then return end
    line.label.Text = text
    local low = text:lower()
    local colour = THEME.muted
    if low:find("refused") or low:find("error") or low:find("can't") or low:find("out of") or low:find("missed") then
        colour = BAD
    elseif low:find("^caught") or low:find("^bought") or low:find("^claimed") or low:find("^hatching") or low:find("^farming")
        or low:find("^upgraded") or low:find("^enrolled") or low:find("^spun") or low:find("^used") or low:find("^opened") then
        colour = GOOD
    end
    line.label.TextColor3 = colour
end
env.__PS99HUB_PUSH_STATUS = function(key, text)
    local lines = linesByKey[key]
    if not lines then return end
    if not S.on[key] then text = "Off" end
    for _, line in ipairs(lines) do paintLine(line, text) end
end
-- tab badges + running chip: redrawn the moment any switch changes
local function refreshCounts()
    local running = 0
    for _, t in ipairs(UI.tabs) do
        local n = 0
        for _, h in ipairs(t.toggles) do if h.get() then n += 1 end end
        t.badge.Text = tostring(n)
        t.badge.Visible = n > 0
        running += n
    end
    UI.runChip.Text = running > 0 and ("%d RUNNING"):format(running) or "ALL IDLE"
    return running
end
env.__PS99HUB_REFRESH_COUNTS = refreshCounts
task.spawn(function()
    local beat = 0
    while alive() do
        for _, line in ipairs(UI.statusLines) do
            local text = S.status[line.key]
            if not S.on[line.key] then text = "Off" end
            if text then paintLine(line, text) end
        end
        local running = refreshCounts()
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
    pcall(function() game:GetService("RunService"):Set3dRenderingEnabled(true) end)
    pcall(function() require(RS.Library.Client.OrbCmds.Orb).DefaultPickupDistance = 20 end)
    pcall(function()
        if env.__PS99HUB_ORB_NEW then
            require(RS.Library.Client.OrbCmds.Orb).new = env.__PS99HUB_ORB_NEW
            env.__PS99HUB_ORB_NEW = nil
        end
    end)
    for k in pairs(S.on) do S.on[k] = false end
    env.__PS99HUB_FARM_ON = false
    pcall(function() G.Variables.OpeningEgg = 0 end)
    pcall(function() UI.sceneHandle.stop() end)
    pcall(function() UI.gui:Destroy() end)
end

UI.toast("PS99 HUB READY", "` search  ·  LeftControl hides the hub", THEME.accent)

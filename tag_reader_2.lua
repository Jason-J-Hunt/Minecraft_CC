-- Sorcerio's Comptuer Craft Ore Scanner
-- Requires a Pocket Computer installed with a "Geo Scanner" from the "Advanced Peripherals" mod.

-- MARK: Configuration

-- The initial radius of the local scans. Note that a limit is imposed on the server end and this value may require adjustment.
local SCAN_RADIUS = 8

-- The block tag to search for when scanning.
local BLOCK_TARGET_TAG = "forge:ores"

-- The cooldown time for the pulse scanner.
local PULSE_COOLDOWN = 2

-- Whether to use the `PULSE_COOLDOWN` or the `scanner.getScanCooldown()` function value for the pulse cooldown time.
local MANUAL_PULSE_COOLDOWN = true

-- The colors use on the radar.
local ORE_PRESENT_COLOR_ABOVE = colors.cyan
local ORE_PRESENT_COLOR_LEVEL = colors.lime
local ORE_PRESENT_COLOR_BELOW = colors.orange
local SCANNER_CENTER_COLOR = colors.white

-- MARK: Functions

-- Clears the screen and prints the header again
-- scanner: A Geo Scanner peripheral.
function printHeader(scanner)
    -- Clear the screen
    term.clear()
    term.setCursorPos(1, 1)

    -- Get the fuel levels
    local infFuelLevel = 2147483647
    local fuelLevel = scanner.getFuelLevel()
    local maxFuelLevel = scanner.getMaxFuelLevel()

    -- Print the title
    print("[ Sorcerio's Ore Scanner ]")

    if (fuelLevel == infFuelLevel) and (maxFuelLevel == infFuelLevel) then
        print("Fuel: Inf")
    else
        print("Fuel: " .. scanner.getFuelLevel() .. " / " .. scanner.getMaxFuelLevel())
    end

    print("Target Tag: " .. BLOCK_TARGET_TAG)
    print("Scan Radius: " .. SCAN_RADIUS)
    print("")
end

-- Checks if a string is in a table.
-- s: The string to search for.
-- tab: The table to search in.
function stringInTable(s, tab)
    for _, v in ipairs(tab) do
        if string.find(v, s, 1, true) then
            return true
        end
    end

    return false
end

-- Calculates the distance between two points in 3D space.
-- x1, y1, z1: The coordinates of the first point.
-- x2, y2, z2: The coordinates of the second point.
function calc3dDistance(x1, y1, z1, x2, y2, z2)
    local dx = x2 - x1
    local dy = y2 - y1
    local dz = z2 - z1
    return math.sqrt(dx * dx + dy * dy + dz * dz)
end

-- Calculates the distance between two points in 1D space.
-- x1: The coordinate of the first point.
-- x2: The coordinate of the second point.
function calc1dDistance(x1, x2)
    return math.abs(x2 - x1)
end

-- Allows for onscreen scrolling of the supplied data.
-- data: A table of data to scroll.
-- pageSize: The number of items to display per page.
-- page: The current page number. Optional.
function scrollData(data, pageSize, page)
    -- Clear the screen
    term.clear()
    term.setCursorPos(1, 1)

    -- Get optionals
    page = page or 1

    -- Calculate the number of pages
    local pageCount = math.ceil(#data / pageSize)

    -- Calculate the start and end index
    local startIndex = (page - 1) * pageSize + 1
    local endIndex = math.min(startIndex + pageSize - 1, #data)

    -- Print the header
    print("Page: " .. page .. " of " .. pageCount)
    print("[a] < | [s] exit | [d] >\n")

    -- Print the data
    for i = startIndex, endIndex do
        print(data[i])
    end

    -- Wait for a key press
    local badKey = true
    while badKey do
        -- Get the key
        local event, key = os.pullEvent("key")

        -- Check the key
        if key == keys.a then
            -- Scroll backward
            badKey = false
            if page > 1 then
                scrollData(data, pageSize, page - 1)
            end
        elseif key == keys.d then
            -- Scroll forward
            badKey = false
            if page < pageCount then
                scrollData(data, pageSize, page + 1)
            end
        elseif key == keys.s then
            -- Quit
            badKey = false
            return
        end
    end
end

-- Scans the local area for ore and shows the results in a scrollable table.
-- scanner: A Geo Scanner peripheral.
-- radius: The radius to attempt to scan.
function scanArea(scanner, radius)
    -- Clear the screen
    term.clear()
    term.setCursorPos(1, 1)

    -- Print the header
    printHeader(scanner)

    -- Print the instructions
    print("Scanning...\n")

    -- Get the scanner data
    local scannerData, scanError = scanner.scan(radius)

    -- Check if the scanner data is nil
    if scannerData == nil then
        -- Report error
        print("An error occured: " .. scanError)
    else
        -- Create display table
        local displayStrings = {}
        for i, data in ipairs(scannerData) do
            -- Check for fields
            if data.name and data.x and data.y and data.z and data.tags then
                -- Check if the tag matches
                if stringInTable(BLOCK_TARGET_TAG, data.tags) then -- TODO: Order by distance
                    -- Add display string
                    table.insert(displayStrings,
                        data.name:match("([^:]+)$") .. " | (" .. data.x .. ", " .. data.y .. ", " .. data.z .. ")")
                end
            end
        end

        -- Delete the scanner data
        scannerData = nil

        -- Show the scrollable data
        scrollData(displayStrings, 7)
    end
end

-- -- Analyzes the chunk for ore.
-- function analyzeChunk(scanner)
--     -- Clear the screen
--     term.clear()
--     term.setCursorPos(1, 1)

--     -- Print the header
--     printHeader(scanner)

--     -- Print the instructions
--     print("Analyzing...\n")

--     -- Get the scanner data
--     local scannerData, scanError = scanner.chunkAnalyze()

--     -- Check if the scanner data is nil
--     if scannerData == nil then
--         -- Report error
--         print("An error occured: " .. scanError)
--     else
--         -- Print the scanner data
--         -- for key, value in pairs(scannerData) do
--         --     print(key .. ": " .. value)
--         -- end
--         scrollData(scannerData, 5)
--     end

--     -- -- Wait for a key press
--     -- print("Press any key to continue.")
--     -- os.pullEvent("key")
-- end

-- Continuously scans the area for the nearest ore and displays the results.
-- scanner: A Geo Scanner peripheral.
-- radius: The radius to attempt to scan.
function scanForNearestOre(scanner, radius)
    -- Enter the scan loop
    local continueScan = true
    local closestName = "None"
    local closestDist = math.huge
    local closestX = math.huge
    local closestY = math.huge
    local closestZ = math.huge
    while continueScan do
        -- Clear the screen
        term.clear()
        term.setCursorPos(1, 1)

        -- Print the header
        printHeader(scanner)

        -- Get the scanner data
        local scannerData, scanError = scanner.scan(radius)

        -- Check if the scanner data is nil
        if scannerData == nil then
            -- Report error
            print("An error occured: " .. scanError .. "\n")
        else
            -- Loop through the scanner data
            local noOreFound = true
            for i, data in ipairs(scannerData) do
                -- Check for fields
                if data.name and data.x and data.y and data.z and data.tags then
                    -- Check if the tag matches
                    if stringInTable(BLOCK_TARGET_TAG, data.tags) then
                        -- Calculate the distance
                        local newDist = calc3dDistance(0, 0, 0, data.x, data.y, data.z)

                        -- Check if the distance is closer
                        if newDist <= closestDist then
                            -- Update the closest data
                            closestName = data.name:match("([^:]+)$")
                            closestDist = newDist
                            closestX = data.x
                            closestY = data.y
                            closestZ = data.z

                            -- Found ore
                            noOreFound = false

                            -- Exit the loop
                            break
                        end
                    end
                end
            end

            -- Nothing found
            if noOreFound then
                closestName = "No ore found."
                closestDist = math.huge
                closestX = math.huge
                closestY = math.huge
                closestZ = math.huge
            end
        end

        -- Print the ore data
        print("Ore: " .. closestName)
        print("X: " .. calc1dDistance(0, closestX))
        print("Y: " .. calc1dDistance(0, closestY))
        print("Z: " .. calc1dDistance(0, closestZ))

        -- Check if manual cooldown
        if MANUAL_PULSE_COOLDOWN then
            -- Wait for the cooldown time
            os.sleep(PULSE_COOLDOWN)
        end
    end
end

-- Displays a 2D grid of the scanner data.
-- scanner: A Geo Scanner peripheral.
function scanRadar(scanner)
    -- Get the size of the terminal
    local termWidth, termHeight = term.getSize()
    local termCenterX = math.floor(termWidth / 2)
    local termCenterY = math.floor(termHeight / 2)

    -- Enter the radar loop
    local continueRadar = true
    local elevationStep = false
    while continueRadar do
        -- Reset the pixel color
        paintutils.drawPixel(1, 1, colors.black)

        -- Clear the screen
        term.clear()

        -- Print the cardinal directions
        term.setCursorPos(termCenterX, 2) -- 1 won't display. Why? IDFK
        print("N")

        term.setCursorPos(termCenterX, termHeight)
        print("S")

        term.setCursorPos(1, termCenterY)
        print("W")

        term.setCursorPos(termWidth, termCenterY)
        print("E")

        -- Add the center point
        paintutils.drawPixel(termCenterX, termCenterY, SCANNER_CENTER_COLOR)

        -- Get the scanner data
        local scannerData, scanError = scanner.scan(SCAN_RADIUS)

        -- Check if the scanner data is nil
        if scannerData == nil then
            -- Report error
            local errX = 3
            local errY = 3
            paintutils.drawPixel(errX, errY, colors.red)
            term.setCursorPos(errX, errY)
            print("An error occured: " .. scanError .. "\n")
        else
            -- Loop through the scanner data
            local noOreFound = true
            for i, data in ipairs(scannerData) do
                -- Check for fields
                if data.name and data.x and data.y and data.z and data.tags then
                    -- Check if the tag matches
                    if stringInTable(BLOCK_TARGET_TAG, data.tags) then
                        -- Calculate the position in the terminal
                        local oreX = termCenterX + data.x
                        local oreY = termCenterY + data.z

                        -- Check if the range is exceeded for the screen
                        local outOfRange = false
                        if (oreX < 1) or (oreX > termWidth) then
                            -- Skip this ore
                            outOfRange = true
                        end

                        if (oreY < 1) or (oreY > termHeight) then
                            -- Skip this ore
                            outOfRange = true
                        end

                        -- Check if in range
                        if not outOfRange then
                            -- Get the color based on the elevation
                            local pixelColor = ORE_PRESENT_COLOR_LEVEL
                            if data.y > 0 then
                                pixelColor = ORE_PRESENT_COLOR_ABOVE
                            elseif data.y < 0 then
                                pixelColor = ORE_PRESENT_COLOR_BELOW
                            end

                            -- Draw the cell
                            paintutils.drawPixel(oreX, oreY, pixelColor)

                            -- Draw elevation data
                            term.setCursorPos(oreX, oreY)
                            if elevationStep then
                                -- Print the number
                                print(math.abs(data.y))
                            else
                                -- Print the direction
                                if data.y > 0 then
                                    print("+")
                                elseif data.y < 0 then
                                    print("-")
                                else
                                    print("=")
                                end
                            end
                        end
                    end
                end
            end
        end

        -- Check if manual cooldown
        if MANUAL_PULSE_COOLDOWN then
            -- Wait for the cooldown time
            os.sleep(PULSE_COOLDOWN)
        end

        -- Toggle elevation step
        elevationStep = not elevationStep
    end
end

-- MARK: Execution
function mainFunction()
    -- Link with the scanner
    local scanner = peripheral.find("geoScanner")
    -- Enter the main loop
    local continueOperation = true
    while continueOperation do
        -- Print the header
        printHeader(scanner)

        -- Print the instructions
        print("Actions:")
        print("[s] View Nearby Ores")
        print("[w] Scan Nearest Ore")
        print("[r] Start Radar")

        print("\nSettings:")
        print("[a] Decrease Scan Radius")
        print("[d] Increase Scan Radius")
        print("[x] Set Target Tag")

        print("\n[q] Quit")

        -- Wait for a key press
        local event, key = os.pullEvent("key")

        -- Check if the key is 'q'
        if key == keys.q then
            -- Exit
            continueOperation = false
        elseif key == keys.s then
            -- Scan for all ores in the area
            scanArea(scanner, SCAN_RADIUS)
        elseif key == keys.w then
            -- Scan for the nearest ore
            scanForNearestOre(scanner, SCAN_RADIUS)
        elseif key == keys.a then
            -- Decrease the scan radius
            SCAN_RADIUS = math.max(1, SCAN_RADIUS - 1)
        elseif key == keys.d then
            -- Increase the scan radius
            SCAN_RADIUS = SCAN_RADIUS + 1
        elseif key == keys.r then
            -- Scan the radar
            scanRadar(scanner)
        elseif key == keys.x then
            -- Set a new target tag
            term.clear()
            term.setCursorPos(1, 1)
            print("Change Target Tag \"" .. BLOCK_TARGET_TAG .. "\" to:")
            BLOCK_TARGET_TAG = read()
        end
    end
end

mainFunction()
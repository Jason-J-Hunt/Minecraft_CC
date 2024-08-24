-- MARK: Configuration

-- The initial radius of the local scans. Note that a limit is imposed on the server end and this value may require adjustment.
local SCAN_RADIUS = 8


-- The cooldown time for the pulse scanner.
local PULSE_COOLDOWN = 2

-- Whether to use the `PULSE_COOLDOWN` or the `scanner.getScanCooldown()` function value for the pulse cooldown time.
local MANUAL_PULSE_COOLDOWN = true

-- Link with the scanner
local scanner = peripheral.find("geoScanner")

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
    print("[Block Identifier]")

    if (fuelLevel == infFuelLevel) and (maxFuelLevel == infFuelLevel) then
        print("Fuel: Inf")
    else
        print("Fuel: " .. scanner.getFuelLevel() .. " / " .. scanner.getMaxFuelLevel())
    end

    print("Scan Radius: " .. SCAN_RADIUS)
    print("")
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

function dump(tbl)
    local values = ""
    for k, v in pairs(tbl) do
        values = values .. "Key: " .. k .. "Values: "
        if type(v) == "table" then
            dump(v)
        else
            values = values .. v
        end
        values = values .. "\n"
    end
    return values
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
            
            ---@type string
            local name = data.name
            ---@type table
            local tags = data.tags

            if data.name and data.x and data.y and data.z and data.tags then
                closestTags = dump(data.tags)
                -- Add display string
                table.insert(displayStrings, name:match("([^:]+)$") .. ": Tags: " .. closestTags)
            end
        end

        -- Delete the scanner data
        scannerData = nil

        -- Show the scrollable data
        scrollData(displayStrings, 7)
    end
end

-- Calculates the distance between two points in 3D space.
-- x1, y1, z1: The coordinates of the first point.
-- x2, y2, z2: The coordinates of the second point.
function calc3dDistance(x1, y1, z1, x2, y2, z2)
    local dx = x2 - x1
    local dy = y2 - y1
    local dz = z2 - z1
    return math.sqrt(dx*dx + dy*dy + dz*dz)
end

-- Fetches data of the nearest block
function scanNearestBlock(scanner, radius)
    local closestName = "None"
    local closestDist = math.huge
    local closestTags = "None"


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
        for i, data in ipairs(scannerData) do
            -- Check for fields
            if data.name and data.x and data.y and data.z and data.tags then
                -- Check if the tag matches
                -- Calculate the distance
                local newDist = calc3dDistance(0, 0, 0, data.x, data.y, data.z)

                -- Check if the distance is closer
                if newDist <= closestDist then
                    -- Update the closest data
                    closestName = data.name:match("([^:]+)$")
                    closestTags = dump(data.tags)
                    break
                end
            end
        end
    end

    -- Print the ore data
    print("Block: " .. closestName)
    print("Tags: " .. closestTags)

end


-- Enter the main loop
local continueOperation = true
while continueOperation do
    -- Print the header
    printHeader(scanner)

    -- Print the instructions
    print("Actions:")
    print("[s] View Nearby Blocks")
    print("[w] Scan Nearest Block")

    print("\nSettings:")
    print("[a] Decrease Scan Radius")
    print("[d] Increase Scan Radius")

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
        scanNearestBlock(scanner, SCAN_RADIUS)
    end
end
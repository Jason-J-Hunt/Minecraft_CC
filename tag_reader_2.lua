function main()
    -- Link with the scanner
    local scanner = peripheral.find("geoScanner")
    -- Enter the main loop
    local continueOperation = true
    while continueOperation do
        -- Print the header
        -- printHeader(scanner)

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
            --[[ scanArea(scanner, SCAN_RADIUS) ]]
            print('Scan Area')
        elseif key == keys.w then
            -- Scan for the nearest ore
            --[[  scanNearestBlock(scanner, SCAN_RADIUS) ]]
            print('Scan closest')
        end
    end
end

main()

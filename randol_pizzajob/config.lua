Config = {}

Config.BossModel = "u_m_y_party_01" -- Ped model of the boss ( https://docs.fivem.net/docs/game-references/ped-models/ )

Config.Payment = 105 -- Per Delivery. Totals up and get paid when you return the vehicle.

Config.BossCoords = vector4(538.35, 101.8, 95.54, 164.05) -- The Blip also uses these coords.

Config.Vehicle = "surge" -- Vehicle you will be delivering in

Config.VehicleSpawn = vector4(535.3, 95.58, 96.32, 159.15) -- Where the vehicle will spawn including it's direction

Config.FuelScript = 'cdn-fuel' -- The fuel script you are using

Config.PayEveryStop = true -- Whether you also want to pay the player after each delivery

Config.PayEveryStopAmount = 5 -- Amount you want to pay them after each stop | If empty will pay 5 dollars

Config.JobLocs = { -- Random delivery houses.
    vector3(224.11, 513.52, 140.92),
    vector3(57.51, 449.71, 147.03),
    vector3(-297.81, 379.83, 112.1),
    vector3(-595.78, 393.0, 101.88),
    vector3(-842.68, 466.85, 87.6),
    vector3(-1367.36, 610.73, 133.88),
    vector3(944.44, -463.19, 61.55),
    vector3(970.42, -502.5, 62.14),
    vector3(1099.5, -438.65, 67.79),
    vector3(1229.6, -725.41, 60.96),
    vector3(288.05, -1094.98, 29.42),
    vector3(-32.35, -1446.46, 31.89),
    vector3(-34.29, -1847.21, 26.19),
    vector3(130.59, -1853.27, 25.23),
    vector3(192.2, -1883.3, 25.06),
    vector3(348.64, -1820.87, 28.89),
    vector3(427.28, -1842.14, 28.46),
    vector3(291.48, -1980.15, 21.6),
    vector3(279.87, -2043.67, 19.77),
    vector3(1297.25, -1618.04, 54.58),
    vector3(1381.98, -1544.75, 57.11),
    vector3(1245.4, -1626.85, 53.28),
    vector3(315.09, -128.31, 69.98),
}
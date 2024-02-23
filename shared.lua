QBCore = exports['qb-core']:GetCoreObject()

return {
    BossModel = `u_m_y_party_01`,
    BossCoords = vec4(538.35, 101.8, 95.54, 164.05), -- The Blip also uses these coords.
    Vehicle = `surge`,
    VehicleSpawn = vec4(535.3, 95.58, 96.32, 159.15),
    FuelScript = {
        enable = true,
        script = 'ps-fuel',
    },
}
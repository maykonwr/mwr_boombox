Speakers = {}
local objects = {}

function SufficientDistance(coords)
    local minDistance = true
    for k,v in pairs(Speakers) do
        local dist = #(coords - v.coords)
        if dist <= 2 and not v.permaDisabled then
            minDistance = false
        end
    end
    return minDistance
end

RegisterNetEvent('mwr_boombox:server:Playsong', function(data)
    if data and data.repro and tonumber(data.repro) and Speakers[tonumber(data.repro + 1)] then
        local v = Speakers[tonumber(data.repro + 1)]
        local songId = GetSongInfo(data.playlist, data.url)
        v.maxDuration = data.playlist.songs[songId].maxDuration
        v.url = data.url
        v.time = data.time
        v.playlistPLaying = data.playlist
        v.isPlaying = false
        v.paused = false
        v.pausedTime = 0
        v.songId = songId
        TriggerClientEvent('mwr_boombox:client:updateBoombox', -1, tonumber(data.repro + 1), v)
    end
end)

RegisterNetEvent('mwr_boombox:server:SyncNewVolume', function(data)
    if data and data.repro and tonumber(data.repro) and Speakers[tonumber(data.repro + 1)] then
        local v = Speakers[tonumber(data.repro + 1)]
        v.volume = data.volume
        TriggerClientEvent('mwr_boombox:client:updateVolume', -1, tonumber(data.repro + 1), v.volume)
    end
end)

RegisterNetEvent('mwr_boombox:server:SyncNewDist', function(data)
    if data and data.repro and tonumber(data.repro) and Speakers[tonumber(data.repro + 1)] then
        local v = Speakers[tonumber(data.repro + 1)]
        if data.dist > 50 then
            data.dist = 50
        elseif data.dist < 2 then
            data.dist = 2
        end
        v.maxDistance = data.dist
        TriggerClientEvent('mwr_boombox:client:updateDist', -1, tonumber(data.repro + 1), v.maxDistance)
    end
end)

RegisterNetEvent('mwr_boombox:server:deleteBoombox', function(id, x)
    local src = source
    if Speakers[id] and Speakers[id].coords and Speakers[id].coords.x and Speakers[id].coords.x == x and not Speakers[id].permaDisabled then
        Speakers[id].permaDisabled = true
        Speakers[id].playlistPLaying = {}
        Speakers[id].url = ''
        if objects[id] and objects[id] ~= -1 and DoesEntityExist(objects[id]) then
            DeleteEntity(objects[id])
        end
        objects[id] = -1
        TriggerClientEvent('mwr_boombox:client:deleteBoombox', -1, id)
        if Config.useItem then
            AddItem(src)
        end
    end
end)

function GetSongInfo(playlist, url)
    if playlist.songs then
        for k,v in pairs(playlist.songs) do
            if v.url == url then
                return k
            end
        end
    else
        return -1
    end
end

Citizen.CreateThread(function()
    while true do
        local sleep = 10000
        local time = os.time() * 1000
        for k,v in pairs(Speakers) do
            if v.playlistPLaying.songs and not v.permaDisabled then
                local nextSong = (v.time + v.maxDuration * 1000) - time
                if sleep > nextSong then
                    sleep = nextSong
                end
                if nextSong <= 0 then
                    if v.playlistPLaying.songs[v.songId + 1] then
                        v.url = v.playlistPLaying.songs[v.songId + 1].url
                        v.time = os.time() * 1000
                        v.isPlaying = false
                        v.songId = v.songId + 1
                        v.maxDuration = v.playlistPLaying.songs[v.songId].maxDuration
                        TriggerClientEvent('mwr_boombox:client:updateBoombox', -1, k, v)
                    else
                        v.url = v.playlistPLaying.songs[1].url
                        v.time = os.time() * 1000
                        v.isPlaying = false
                        v.songId = 1
                        v.maxDuration = v.playlistPLaying.songs[1].maxDuration
                        TriggerClientEvent('mwr_boombox:client:updateBoombox', -1, k, v)
                    end
                end
            end
        end
        Wait(sleep)
    end
end)

CreateCallback("mwr_boombox:callback:getBoomboxs", function(source, cb)
	cb(Speakers)
end)

function ExistPlaylist(playlists, playlistId)
    for k,v in pairs(playlists) do
        if v.id == playlistId then
            return k
        end
    end
    return - 1
end

CreateCallback("mwr_boombox:callback:getPlaylists", function(source, cb)
    local license = GetPlayerIdentifierByType(source, 'license')
    MySQL.Async.fetchAll("SELECT mwr_playlists.id AS playlistId, mwr_playlist_songs.id AS songIdInPlaylist, mwr_playlists.name AS PlaylistName, mwr_songs.url, mwr_songs.name, mwr_songs.author, mwr_songs.maxDuration FROM mwr_playlists_users LEFT JOIN mwr_playlist_songs ON mwr_playlists_users.playlist = mwr_playlist_songs.playlist LEFT JOIN mwr_playlists ON mwr_playlists_users.playlist = mwr_playlists.id LEFT JOIN mwr_songs ON mwr_playlist_songs.song = mwr_songs.id WHERE license = @license", {['@license'] = license}, function(results)        local playlists = {}
        for k,v in pairs(results) do
            local ExistPlaylist = ExistPlaylist(playlists, v.playlistId)
            if ExistPlaylist ~= -1 then
                table.insert(playlists[ExistPlaylist].songs, {id = v.songIdInPlaylist, url = v.url, name = v.name, author = v.author, maxDuration = v.maxDuration})
            else
                if v.songIdInPlaylist then
                    table.insert(playlists, {id = v.playlistId, name = v.PlaylistName, songs = {{id = v.songIdInPlaylist, url = v.url, name = v.name, author = v.author, maxDuration = v.maxDuration}}})
                else
                    table.insert(playlists, {id = v.playlistId, name = v.PlaylistName, songs = {}})
                end
            end
        end
        cb(playlists)
    end)
end)

CreateCallback("mwr_boombox:callback:getNewPlaylist", function(source, cb, data)
    local license = GetPlayerIdentifierByType(source, 'license')
    if data == '' then
        data = Config.Translations.newPlaylist
    end
    local idPlaylist = MySQL.insert.await('INSERT INTO mwr_playlists (name, owner) VALUES (?, ?)', {
        data,
        license
    })
    local idPlaylistUser = MySQL.insert.await('INSERT INTO mwr_playlists_users (playlist, license) VALUES (?, ?)', {
        idPlaylist,
        license
    })
    cb(idPlaylist)
end)

RegisterNetEvent('mwr_boombox:server:addSong', function(data)
    local src = source
    MySQL.Async.fetchAll("SELECT id FROM mwr_songs WHERE url = @url", {['@url'] = data.url}, function(results)
        if results[1] and results[1].id then
            local idSongInPlaylist = MySQL.insert.await('INSERT INTO mwr_playlist_songs (playlist, song) VALUES (?, ?)', {
                data.playlistActive,
                results[1].id
            })
            TriggerClientEvent('mwr_boombox:client:resyncPlaylists', src)
        else
            local idSong = MySQL.insert.await('INSERT INTO mwr_songs (url, maxDuration, name, author) VALUES (?, ?, ?, ?)', {
                data.url,
                data.maxDuration,
                data.name,
                data.author
            })
            local idSongInPlaylist = MySQL.insert.await('INSERT INTO mwr_playlist_songs (playlist, song) VALUES (?, ?)', {
                data.playlistActive,
                idSong
            })
            TriggerClientEvent('mwr_boombox:client:resyncPlaylists', src)
        end
    end)
end)

RegisterNetEvent('mwr_boombox:server:deletePlayList', function(data)
    local src = source
    local license = GetPlayerIdentifierByType(src, 'license')
    MySQL.query('DELETE FROM mwr_playlists_users WHERE playlist = ? and license = ?', { data, license }, function()
        TriggerClientEvent('mwr_boombox:client:resyncPlaylists', src)
    end)
end)

RegisterNetEvent('mwr_boombox:server:importNewPlaylist', function(data)
    local src = source
    local license = GetPlayerIdentifierByType(src, 'license')
    MySQL.Async.fetchAll("SELECT id FROM mwr_playlists_users WHERE playlist = @playlist and license = @license", {['@playlist'] = tonumber(data), ['@license'] = license}, function(results)
        if #results < 1 then
            local id = MySQL.insert.await('INSERT INTO mwr_playlists_users (license, playlist) VALUES (?, ?)', {
                license,
                data
            })
            if id then
                TriggerClientEvent('mwr_boombox:client:resyncPlaylists', src)
            end
        end
    end)
end)

RegisterNetEvent('mwr_boombox:server:deleteSongPlaylist', function(data)
    local src = source
    local license = GetPlayerIdentifierByType(src, 'license')
    MySQL.Async.fetchAll("SELECT owner FROM mwr_playlists WHERE id = @playlist", {['@playlist'] = tonumber(data.playlist)}, function(results)
        if results[1].owner == license then
            MySQL.query('DELETE FROM mwr_playlist_songs WHERE id = ? and playlist = ?', { data.songId, data.playlist }, function()
                TriggerClientEvent('mwr_boombox:client:resyncPlaylists', src)
            end)
        end
    end)
end)

RegisterNetEvent('mwr_boombox:server:nextSong', function(data)
    if data and data.repro and tonumber(data.repro) and Speakers[tonumber(data.repro + 1)] then
        local v = Speakers[tonumber(data.repro + 1)]
        local songId = GetSongInfo(v.playlistPLaying, v.url)
        if v.playlistPLaying.songs[songId + 1] then
            songId = songId + 1
            v.maxDuration = v.playlistPLaying.songs[songId].maxDuration
            v.url = v.playlistPLaying.songs[songId].url
            v.time = data.time
            v.isPlaying = false
            v.songId = songId
            v.paused = false
            v.pausedTime = 0
        else
            if v.playlistPLaying.songs[1] then
                v.maxDuration = v.playlistPLaying.songs[1].maxDuration
                v.url = v.playlistPLaying.songs[1].url
                v.time = data.time
                v.isPlaying = false
                v.songId = 1
                v.paused = false
                v.pausedTime = 0
            end
        end
        TriggerClientEvent('mwr_boombox:client:updateBoombox', -1, tonumber(data.repro + 1), v)
    end
end)

RegisterNetEvent('mwr_boombox:server:prevSong', function(data)
    if data and data.repro and tonumber(data.repro) and Speakers[tonumber(data.repro + 1)] then
        local v = Speakers[tonumber(data.repro + 1)]
        local songId = GetSongInfo(v.playlistPLaying, v.url)
        if v.playlistPLaying.songs[songId - 1] then
            songId = songId - 1
            v.maxDuration = v.playlistPLaying.songs[songId].maxDuration
            v.url = v.playlistPLaying.songs[songId].url
            v.time = data.time
            v.isPlaying = false
            v.songId = songId
            v.paused = false
            v.pausedTime = 0
        else
            if v.playlistPLaying.songs[#v.playlistPLaying.songs] then
                v.maxDuration = v.playlistPLaying.songs[#v.playlistPLaying.songs].maxDuration
                v.url = v.playlistPLaying.songs[#v.playlistPLaying.songs].url
                v.time = data.time
                v.isPlaying = false
                v.songId = #v.playlistPLaying.songs
                v.paused = false
                v.pausedTime = 0
            end
        end
        TriggerClientEvent('mwr_boombox:client:updateBoombox', -1, tonumber(data.repro + 1), v)
    end
end)

RegisterNetEvent('mwr_boombox:server:syncNewTime', function(data)
    if data and data.repro and tonumber(data.repro) and Speakers[tonumber(data.repro + 1)] then
        local v = Speakers[tonumber(data.repro + 1)]
        v.time = data.time
        TriggerClientEvent('mwr_boombox:client:updateBoombox', -1, tonumber(data.repro + 1), v)
    end
end)

RegisterNetEvent('mwr_boombox:server:pauseSong', function(data)
    if data and data.repro and tonumber(data.repro) and Speakers[tonumber(data.repro + 1)] then
        local v = Speakers[tonumber(data.repro + 1)]
        if not v.paused then
            v.paused = true
            v.pausedTime = data.value
        else
            v.paused = false
            v.time = data.time - (v.pausedTime * 1000)
        end
        TriggerClientEvent('mwr_boombox:client:updateBoombox', -1, tonumber(data.repro + 1), v)
    end
end)

function CreateSpeaker(src)
    local enoughDistance = SufficientDistance(GetEntityCoords(GetPlayerPed(src)))
    if enoughDistance then
        local data = {volume = 50, url = '', coords = GetEntityCoords(GetPlayerPed(src)), playlistPLaying = {}, time = 0, maxDistance = 15, isPlaying = false, maxDuration = 5000000, songId = -2, permaDisabled = false, paused = false, pausedTime = 0, isMoving = false, playerMoving = -2}
        table.insert(Speakers, data)
        if Config.useItem then
            DeleteItem(src)
        end
        TriggerClientEvent('mwr_boombox:client:doAnim', src)
        Citizen.Wait(1000)
        local obj = CreateObject(Config.RadioProp, data.coords - vector3(0.0, 0.0, 1.0), true, false, true)
        table.insert(objects, obj)
        TriggerClientEvent('mwr_boombox:client:insertSpeaker', -1, data)
    else
        TriggerClientEvent('mwr_boombox:client:notify', src, Config.Translations.notEnoughDistance)
    end
end

AddEventHandler('onResourceStop', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then
        return
    end
    for k,v in pairs(objects) do
        if v ~= -1 and DoesEntityExist(v) then
            DeleteEntity(v)
        end
    end
end)

CreateCallback("mwr_boombox:callback:canMove", function(source, cb, id)
    local src = source
    if not Speakers[id].isMoving then
        Speakers[id].isMoving = true
        Speakers[id].playerMoving = src
        if objects[id] and objects[id] ~= -1 and DoesEntityExist(objects[id]) then
            DeleteEntity(objects[id])
        end
        objects[id] = -1
        TriggerClientEvent('mwr_boombox:client:updatePlayerMoving', -1, id, src)
    end
    cb(Speakers[id].isMoving)
end)

RegisterNetEvent('mwr_boombox:server:updateObjectCoords', function(id)
    local src = source
    if Speakers[id].isMoving and Speakers[id].playerMoving == src then
        local coords = GetEntityCoords(GetPlayerPed(src))
        local obj = CreateObject(Config.RadioProp, coords - vector3(0.0, 0.0, 1.0), true, false, true)
        objects[id] = obj
        Speakers[id].isMoving = false
        Speakers[id].coords = coords
        Speakers[id].playerMoving = -1
        TriggerClientEvent('mwr_boombox:client:syncLastCoords', -1, id, coords)
    end
end)
Config = Config or {}
Config.framework = 'qbcore' --(qbcore/esx/custom)
Config.useItem = true -- If disabled, you can use the command /createSpeaker
Config.fixSpeakersCommand = "fixSpeakers" --If speakers dont load use this command to reload all the speakers
Config.itemName = 'speaker' --You need to had this item created in your config or database
Config.timeZone = "America/Sao_Paulo" --IMPORTANT to set what time zone is your server in https://gist.github.com/mur4i/357734b2baebe353fe932302fb561650
Config.KeyAccessUi = 38
Config.KeyToPlaceSpeaker = 191
Config.KeyToChangeAnim = 38
Config.RadioProp = 'prop_boombox_01' -- Defina o prop do rádio (default = prop_boombox_01)


Config.Translations = {
    notEnoughDistance = 'Você deve manter um pouco mais de distância do outro alto-falante próximo.',
    helpNotify = 'Pressione ~INPUT_CONTEXT~ para acessar o alto-falante',
    libraryLabel = 'Sua biblioteca',
    newPlaylistLabel = 'Criar nova Playlist',
    importPlaylistLabel = 'Importar uma Playlist existente',
    newPlaylist = 'Nova Playlist',
    playlistName = 'Nome da Playlist',
    addSong = 'Adicionar música',
    deletePlaylist = 'Deletar Playlist',
    unkown = 'Desconhecido',
    titleFirstMessage = "Ainda não tem uma playlist?",
    secondFirstMessage = "Crie uma Playlist",
    holdingBoombox = 'Pressione ~INPUT_FRONTEND_RDOWN~ para colocar o alto-falante ou ~INPUT_CONTEXT~ para mudar a animação'
}
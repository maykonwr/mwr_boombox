fx_version "cerulean"

description "A boombox script that play yt music by MwR"
author "MwR"

lua54 'yes'

games {
  "gta5"
}

ui_page 'web/build/index.html'

-- shared_script '@es_extended/imports.lua' --Import this if you are using es_extended

client_scripts {
  'Config.lua',
  "client/**/*"
}
server_script {
  "@oxmysql/lib/MySQL.lua",
  'Config.lua',
  "server/**/*"
}

files {
	'web/build/index.html',
	'web/build/**/*'
}

dependencies {
  'oxmysql'
}
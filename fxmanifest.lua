fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'h4nr-crosshair'
author 'FeatherFrameworkFiveM'
description 'Standalone customizable GTA V crosshair with Feather Menu v2 settings'
version '0.2.1'

shared_script 'config.lua'

client_scripts {
    'client/model.lua',
    'client/main.lua'
}

server_script 'server/chat_suggestions.lua'

dependency 'feather-menu-v2'

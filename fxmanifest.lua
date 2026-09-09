fx_version 'cerulean'
game 'gta5'

author 'Baylorai'
description 'bd-rentals'
version '1.5.0'


shared_scripts {
    'config.lua',
    '@ox_lib/init.lua'
}

client_scripts {
    'client.lua',
}

server_script {
    'server.lua'
}

dependencies {
    'ox_lib',
}

lua54 'yes'

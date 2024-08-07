fx_version 'cerulean'
game 'gta5'

author 'Baylorai'
description 'rt-rentals'
version '1.0.1'


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

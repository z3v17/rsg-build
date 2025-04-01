fx_version 'cerulean'
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'
game 'rdr3'

author 'z3v'
description 'Sistema de Construcción para RedM'
version '1.0.0'

-- Configuración compartida
shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}

-- Scripts del servidor
server_scripts {
    '@oxmysql/lib/MySQL.lua', -- Necesario para base de datos
    'server.lua'
}

-- Scripts del cliente
client_scripts {
    'client.lua'
}

-- Dependencias necesarias
dependencies {
    'rsg-core',
    'ox_lib',
    -- 'oxmysql',  -- Para manejar la base de datos
    -- 'ox_target' -- Para la interacción con objetos
}

lua54 'yes'

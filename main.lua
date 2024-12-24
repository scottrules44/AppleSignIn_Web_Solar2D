
local appleSignIn = require "plugin.appleSignIn"
local json = require "json"
local bg = display.newRect( display.contentCenterX, display.contentCenterY, display.actualContentWidth, display.actualContentHeight )
bg:setFillColor(1)
local title = display.newText( "Apple Sign In", display.contentCenterX, display.contentCenterY-100, native.systemFontBold, 20 )
title:setFillColor( 0 )
local signIn = display.newImageRect( "appleSignIn.png", 160, 30 )
signIn.x, signIn.y = display.contentCenterX, display.contentCenterY
signIn:addEventListener( "touch", function ( e )
    if (e.phase == "began") then
        signIn.alpha = .5
    elseif (e.phase == "ended" or e.phase == "cancelled") then
        signIn.alpha = 1
        appleSignIn.show("nameAndEmail", function (e)
            print(json.encode(e))
         end , { clientId = "tech.scotth.apple-sign-in", domain = "cloud.scotth.tech" }  )
    end
end )

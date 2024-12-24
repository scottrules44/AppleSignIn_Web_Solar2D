local m = {}

function split(inputStr, delimiter)
    local result = {}
    for match in (inputStr .. delimiter):gmatch("(.-)" .. delimiter) do
        table.insert(result, match)
    end
    return result
end
function string.urlEncode( str )
 
    if ( str ) then
        str = string.gsub( str, "\n", "\r\n" )
        str = string.gsub( str, "([^%w ])",
            function( c )
                return string.format( "%%%02X", string.byte(c) )
            end
        )
        str = string.gsub( str, " ", "+" )
    end
    return str
end
function string.urlDecode(str)
    if str then
        str = string.gsub(str, "+", " ") -- Replace '+' with spaces
        str = string.gsub(str, "%%(%x%x)", function(hex)
            return string.char(tonumber(hex, 16)) -- Convert %XX to the corresponding character
        end)
    end
    return str
end

m.show = function(typeS, listener, credentials)
    if(credentials == nil) then 
        print("Credentials are need for Web Auth")
        return
    end
    -- Assuming credentials is a table with client_id and scope fields
    local clientId = credentials.clientId or "default-client-id" -- Fallback if not provided
    local scopes = "email"
    local domain = credentials.domain or "cloud.scotth.tech"
    if typeS == "name" then
        scopes = "name"
    elseif typeS == "nameAndEmail" then
        scopes = "email name"
    end
    -- Function to generate a random nonce (a secure random string)
    local function generateNonce(length)
        length = length or 32
        local charset = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
        local nonce = ""
        for i = 1, length do
            local randomIndex = math.random(1, #charset)
            nonce = nonce .. string.sub(charset, randomIndex, randomIndex)
        end
        return nonce
    end

    -- Generate a nonce
    local nonce = generateNonce()

    -- Construct the redirect URI
    local redirectUri = "https://" .. domain .. "/apple_process_sign_in_solar2d"

    -- Construct the Apple Sign-In URL
    local appleAuthUrl = "https://appleid.apple.com/auth/authorize?" ..
        "client_id=" .. string.urlEncode(clientId) ..
        "&redirect_uri=" .. string.urlEncode(redirectUri) ..
        "&response_type=code%20id_token" ..
        "&scope=" .. string.urlEncode(scopes) ..
        "&nonce=" .. string.urlEncode(nonce) ..
        "&response_mode=form_post"
    -- Create a new WebView and load the constructed URL
    local aspectRatioHeight = display.actualContentHeight/480
    local aspectRatioWidth = display.actualContentWidth/320
    local popupGroup = display.newGroup()
    local overlay = display.newRect( popupGroup,display.contentCenterX, display.contentCenterY, display.actualContentWidth, display.actualContentHeight )
    local topGrayBar = display.newRect( popupGroup, display.contentCenterX, display.safeScreenOriginY+(20*aspectRatioHeight), display.safeActualContentWidth, (40*aspectRatioHeight) )
    topGrayBar:setFillColor( .5 )
    local x = display.newText( popupGroup, "X", display.safeScreenOriginX+(15*aspectRatioWidth), display.safeScreenOriginY+(14*aspectRatioHeight), native.systemFontBold, 23*aspectRatioHeight )
    local webView = native.newWebView(display.contentCenterX, display.contentCenterY+(25*aspectRatioHeight), display.safeActualContentWidth, display.safeActualContentHeight-(25*aspectRatioHeight))
    webView:request(appleAuthUrl)
    popupGroup:insert(webView)
    x:addEventListener( "touch", function ( e )
        if (e.phase == "began") then
            x.alpha = .5
        elseif (e.phase == "ended" or e.phase == "cancelled") then
            x.alpha = 1
            webView:removeSelf()
            webView = nil
            popupGroup:removeSelf()
            popupGroup = nil
            listener({
                isError = true,
                error = "User cancelled"
            })
        end
    end )

    local function webListener(event)
        print(event.url)
        if event.url and event.url:find("/apple_pending_page") then 
    
            -- Extract query parameters from the updated URL
            local paramsString = event.url:match("%?(.*)")
            if paramsString then
                local params = {}
                for key, value in paramsString:gmatch("([^&=?]+)=([^&=?]+)") do
                    params[key] = string.urlDecode(value)
                end
    
                -- Handle errors or success
                if params.error then
                    listener({
                        isError = true,
                        error = params.error
                    })
                    print("Error: " .. (params.message or "Unknown error"))
                else
                    local nameSplit = split(params.name, "*")
                    listener({
                        isError = false,
                        identityToken = params.id_token,
                        authorizationCode = params.code,
                        user = params.userId,
                        email = params.email,
                        fullName = {
                            givenName = nameSplit[1],
                            familyName = nameSplit[2]
                        }
                    })
                end
    
                -- Close the WebView after processing the result
                webView:removeSelf()
                webView = nil
            end
        end
    end
    webView:addEventListener("urlRequest", webListener)    
end

m.getCredentialState = function()
    print("Not supported on Solar2D")
end
return m
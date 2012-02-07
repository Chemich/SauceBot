 ###########################################################
#                                                           #
# - Node.js implementation of the SauceBot Command Server - #
#                                                           #
 ###########################################################

# Config
Sauce = require './sauce'

# Sauce
db    = require './saucedb'
users = require './users'
chans = require './channels'

# Utility
io    = require './ioutil'

# Node.js
net   = require 'net'
sys   = require 'sys'
url   = require 'url'
color = require 'colors'

# Load users from the database
io.debug 'Loading users...'
users.load (userlist) ->
    io.debug "Loaded #{(Object.keys userlist).length} users."

# Load channels from the database
io.debug 'Loading channels...'
chans.load (chanlist) ->
    io.debug "Loaded #{(Object.keys chanlist).length} channels."


# SauceBot connection handler class
class SauceBot
    
    constructor: (@socket) ->
        
        # Set up input-handler for the client
        @socket.on 'data', (rawdatas) =>
            return unless rawdatas

            rawdata = rawdatas.split "\n"
            for raw in rawdata
                continue unless raw

                try
                    @handle JSON.parse(raw)
                catch error
                    @sendError "Syntax error: #{error}"

    handle: (json) ->
        chan      = json.chan

        # Normalize json.op
        json.op   = if json.op then 1 else null

        # Split the arguments by space
        json.args = json.args.split ' '

        # Handle the message
        chans.handle chan, json, (data) =>
            @say chan, "#{io.noise()} #{data}"
        , =>
            

    # Sends an error to the client
    sendError: (message) ->
        json = JSON.stringify
                error: 1,
                msg  : message

        io.say '>> '.red + message
        @socket.write "#{json}\n"


    # Sends a 'say' message to the client
    say: (channel, message) ->
        @send 'say', channel, message

  
    # Sends a 'timeout' message to the client
    # - Times out the target user for 10 minutes
    timeout: (channel, user) ->
        @send 'timeout', channel, user
        
    
    # Sends a 'clear' message to the client
    # - Clears the targets messages
    clear: (channel, user) ->
        @send 'clear', channel, user
        
        
    # Sends a 'ban' message to the client
    # - Bans the target user
    ban: (channel, user) ->
        @send 'ban', channel, user


    # Sends an 'unban' message to the client
    # - Unbans the target user
    unban: (channel, user) ->
        @send 'unban', channel, user


    # Sends a message to the client
    send: (action, channel, message) ->
        json = JSON.stringify
                act : action
                chan: channel
                msg : message

        io.say '>> '.magenta + "#{action} #{channel}: #{message}"
        @socket.write "#{json}\n"

# Main
server = net.createServer (socket) ->
    socket.setEncoding 'utf8'
    ip = socket.remoteAddress
    
    io.say 'Client connected: '.magenta + ip
    
    client = new SauceBot socket

    socket.on 'end', ->
        io.say 'Client disconnected: '.magenta + ip


server.listen Sauce.PORT
io.say "Server started on port #{Sauce.PORT}".cyan

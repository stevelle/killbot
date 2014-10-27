# OscarRobo will fill the world with bad attitude.
#
# OscarRobo losses - Ask about recent losses by your corp
# OscarRobo kills - Ask about recent kills by your corp
# OscarRobo version - Ask Oscar about what version he is running
# I hate <target> - Oscar will insult <target>
# (and in random conversation) - Oscar will otherwise snark in channel, spam with image macros, and othwerwise be a twit until banned

# Must Set HUBOT_CORP_ID environment var in hubot's ENV
# Must Set HUBOT_OPERATOR_EMAIL environment var as well
# TODO ensure these are set
corp_id = process.env.HUBOT_CORP_ID
email = process.env.HUBOT_OPERATOR_EMAIL
version = "0.0.2"

#   depends on xml2json - so `npm install xml2json` already
#   also depends on zlip
parser = require('xml2json')
zlib = require('zlib')

module.exports = (robot) ->
  robot.respond /(kills|losses)/i, (msg) ->
    if !corp_id?
      msg.send "I can't do that. Someone forgot to tell me the corporation ID you care about."
      return
    
    msg.send "Give me a moment..."
    data = ""
    # TODO Number of hours should be from ENV
    msg.http("https://zkillboard.com/api/#{msg.match[1]}/corporationID/#{corp_id}/pastSeconds/108000/")
      .headers('Accept': 'application/json', 'Accept-Encoding': 'gzip', 'User-Agent': "OscarRobo/#{version} [#{email}] (on Hubot/2.9.0)")
      .get( (err, req) ->
        req.addListener "response", (res)->
          output = zlib.createGunzip()
          res.pipe(output)

          output.on 'data', (d)->
            data += d.toString('utf-8')

          output.on 'end', ()->
            parsedData = JSON.parse(data)
            if parsedData.error
              robot.emit 'error', parsedData.error.message
              return

            if (parsedData.length == 0)
              msg.send "Nothing showing recently."
              return
            
            robot.http("https://api.eveonline.com/Eve/TypeName.xml.aspx?ids=#{parsedData[0].victim.shipTypeID}")
              .get() (err2, res2, xml) ->
                if res2.statusCode isnt 200 or err2
                  robot.emit 'error', err2, res2
                  return
                ship = JSON.parse(parser.toJson(xml)).eveapi.result.rowset.row.typeName
                msg.send "#{parsedData[0].victim.characterName} died last in a #{ship} " +
                  "and there are #{parsedData.length - 1} other #{msg.match[1]} recently." 
      )()
  robot.hear /^kills$|^losses$/i, (msg) ->
    msg.send "you didn't say Simon Says!"

  robot.respond /version/i, (msg) ->
    msg.send "I'm running version #{version}"

  robot.hear /damn|fucking/i, (msg) ->
    msg.send msg.random schadenfreude

  robot.hear /I hate (.*)/i, (msg) ->
    msg.send msg.random(insults) + " #{msg.match[1]}"

  robot.hear /([A-Z]{4,})/, (msg) ->
    msg.send "Did someone light a cyno?  All I see are caps everywhere."

  robot.hear /tired|too hard|to hard|upset|bored/i, (msg) ->
    msg.send "https://www.youtube.com/watch?v=S5xvkAPXB9c"

  robot.hear /doctrine/i, (msg) ->
    msg.emote "gasps and faints"

  robot.hear /blue funnelcake/i, (msg) ->
    msg.send "Yeah, fuck those guys.  Rabble rabble."

  robot.hear /wb|welcome back/i, (msg) ->
    msg.send "http://imagemacros.files.wordpress.com/2009/06/clowntrain.jpeg"

  robot.hear /failed|derped/i, (msg) ->
    msg.send "http://imagemacros.files.wordpress.com/2011/11/nice_glass_derp.jpg"

  robot.hear /is down/, (msg) ->
    msg.send "http://imagemacros.files.wordpress.com/2010/02/roger_american_dad_technical_problems.png"

  robot.error (err, msg) ->
    robot.logger.error "BARF! #{err}"

# Debugging Aids
cache = [] 
censor = (k, v) ->
  if (typeof v == 'object' && v != null)
    if (cache.indexOf(v) != -1)
      return 
    cache.push(v)
  v

schadenfreude = [
  "U mad bro?",
  "Your delicious tears sustain me.",
  "Can I have your stuff?",
  "Someone needs a hug."
]

insults = [
    "DIAF (In Game)",
    "You have all the virtues I dislike and none of the vices I admire,",
    "Delusions of adequacy is my official diagnosis of",
    "Do us a favor, sit in the corner and stop breathing",
    "Dude.... your FACE. For the love of all that is Holy in Domain, just stop moving it",
    "Your mother is so fat she collapsed the EVEGate,",
    "Your father is a Fedo and your mother smells of stale Quafe,",
    "Somebody trained Moron to V. Not naming names :cough:"
]

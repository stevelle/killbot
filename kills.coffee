# OscarRobo will fill the world with bad attitude.
#
# !losses - Ask about recent losses by your corp
# !kills - Ask about recent kills by your corp
# OscarRobo sleep - Mute OscarRobo's snark for 15 minutes
# OscarRobo wake - Unmute OscarRobo's snark
# I hate <target> - Oscar will insult <target>
# ...(and in random conversation) - Oscar will otherwise snark in channel, spam with image macros, and othwerwise be a twit until muted

# Must Set HUBOT_CORP_ID environment var in hubot's ENV
# Must Set HUBOT_OPERATOR_EMAIL environment var as well
# TODO ensure these are set
corp_id = process.env.HUBOT_CORP_ID
email = process.env.HUBOT_OPERATOR_EMAIL
version = "0.0.3"

#   depends on xml2json - so `npm install xml2json` already
#   depends on moment - so `npm install moment` already
#   also depends on zlip
parser = require('xml2json')
zlib = require('zlib')
moment = require('moment')
Util = require('util')

module.exports = (robot) ->
  robot.hear /^!(kills|losses) in ([0-9]+) ([a-zA-Z]+)/i, (msg) ->
    if !corp_id?
      msg.send "I can't do that. Someone forgot to tell me the corporation ID you care about."
      return
    
    msg.send "Give me a moment..."
    data = ""
    window = msg.match[2]
    unit = msg.match[3].toLowerCase()
    # TODO corp ID from brain by ticker
    from_time = moment().utc().subtract(window, unit).format("YYYYMMDDHHmmss")
    msg.http("https://beta.eve-kill.net/api/#{msg.match[1]}/corporationID/#{corp_id}/startTime/#{from_time}/")
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
              msg.send parsedData.error.message
              return

            if (parsedData.length == 0)
              msg.send "Nothing showing recently."
              return
            
            for idx in [0..parsedData.length-1]
              report_kill(robot, msg, parsedData[idx])
      )()

  robot.hear /damn |fucking /i, (msg) ->
    if (awake(robot)) 
      msg.send msg.random schadenfreude

  robot.hear /I hate (.*)/i, (msg) ->
    if (awake(robot)) 
      msg.send "Yeah. I do too."
      #msg.send msg.random(insults) + " #{msg.match[1]}"

  robot.hear /[A-Z]{3,}[,.\-!\? ]?[A-Z]{4,} ?[^a-z]*/, (msg) ->
    if (awake(robot)) 
      for key in ['http', 'WHAPP', 'ADHC', 'CYNOU', 'TISHU', 'youtu']
        if msg.message.text.indexOf(key) > -1
          return
      msg.send "Did someone light a cyno?  All I see are caps everywhere."

  robot.hear /doctrine/i, (msg) ->
    if (awake(robot)) 
      msg.emote "gasps and faints"

  robot.hear /blue funnelcake|got blobbed|by blobbers/i, (msg) ->
    if (awake(robot)) 
      msg.send "Yeah, fuck those guys. Rabble rabble."

  robot.hear /bringin[g]? solo back/i, (msg) ->
    if (awake(robot))
      msg.send "My hero. https://pbs.twimg.com/profile_images/464717630968848385/Ji9pV1Ai_200x200.jpeg"

  robot.hear /^wb [a-z]+|^wb$|welcome back/i, (msg) ->
    if (awake(robot)) 
      msg.send "http://imagemacros.files.wordpress.com/2009/06/clowntrain.jpeg"

  robot.hear /failed [^over]|derped/i, (msg) ->
    if (awake(robot)) 
      msg.send "http://imagemacros.files.wordpress.com/2011/11/nice_glass_derp.jpg"

  robot.hear /is down/, (msg) ->
    if (awake(robot)) 
      msg.send "http://imagemacros.files.wordpress.com/2010/02/roger_american_dad_technical_problems.png"

  robot.respond /stfu|shut up|mute|sleep|diaf/i, (msg) ->
    wake = moment().add(15, 'm')
    robot.brain.set 'sleepUntil', wake
    msg.send "Do you want me to sit in a corner and rust or just fall apart where I'm standing?"

  robot.respond /wake|rise and shine|unmute/i, (msg) ->
    robot.brain.set 'sleepUntil', moment()
    msg.send "This will all end in tears."

  robot.error (err, msg) ->
    robot.logger.error "BARF! #{err}"

#semi-mute
#if (msg.random([0..10]) < 3)

report_kill = (robot, msg, kill) ->
  name_for_id(robot, msg, kill.victim.shipTypeID, (msg, ship) ->
    msg.send "#{kill.victim.characterName} died last in a #{ship}" # + " https://beta.eve-kill.net/kill/#{kill.killID}" 
  )

name_for_id = (robot, msg, id, callback) ->
  name = robot.brain.get "itemID.#{id}"
  if name?
    callback(msg, name)
  else
    msg.http("https://api.eveonline.com/Eve/TypeName.xml.aspx?ids=#{id}")
      .get() (err2, res2, xml) ->
        if res2.statusCode isnt 200 or err2
          return '<unknown: #{id}>'
        tree = JSON.parse(parser.toJson(xml))
        robot.brain.set "itemID.#{id}", tree.eveapi.result.rowset.row.typeName
        callback(msg, tree.eveapi.result.rowset.row.typeName)

awake = (robot) ->
  wake = robot.brain.get 'sleepUntil' 
  if wake?
    return wake <= moment()
  return true

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

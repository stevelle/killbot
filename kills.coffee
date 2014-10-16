# hubot kills reporter.
#   Must Set HUBOT_CORP_ID environment var in hubot's ENV
#   depends on xml2json - so `npm install xml2json` already
#(losses) - Ask about recent corp losses

# TODO ensure this is set
corp_id = process.env.HUBOT_CORP_ID
parser = require('xml2json')
module.exports = (robot) ->
  robot.respond /losses/i, (msg) ->
    try
      # TODO Number of hours should be from ENV
      robot.http("https://zkillboard.com/api/losses/corporationID/#{corp_id}/pastSeconds/108000/")
        .get() (err, res, body) ->
          if err
            msg.send "I could tell you, but then I'd have to kill you. Because #{err}"
            return
          data = JSON.parse(body)
          msg.send "Hi there"
          if (data.length == 0)
            msg.send "Nothing in the last 3 hours."
          else
            # FIXME Ship Type isn't working yet.  Figure that out
            shipType = "unknown ship type"
            robot.http("https://api.eveonline.com/Eve/TypeName.xml.aspx?ids=#{data[0].victim.shipTypeID}")
              .get() (err2, res2, body2) ->
                if !err2
                  shipType = parser.toJson(body2)
            msg.send "#{data[0].victim.characterName} died last in a #{shipType} " +
              "and there are #{data.length - 1} other losses in 3 hours." 
    catch error
      msg.send "oops. #{error}"


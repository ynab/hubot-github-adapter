{TextMessage} = require 'hubot'

class GithubMessage extends TextMessage
  # Represents an incoming message from the chat.
  #
  # user - A User instance that sent the message.
  # text - A String message.
  # id   - A String of the message ID.
  # postdata   - The full body of the post data
  constructor: (@user, @text, @id, @githubPayload) ->
    super @user, @text, @id

module.exports = GithubMessage
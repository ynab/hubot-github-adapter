
# I wrote this adapter by adapting Slack's adapter: https://github.com/slackhq/hubot-slack
# Similarities are not coincidental. Thank you Slack!
{Robot, Adapter, TextMessage} = require 'hubot'

GitHubApi = require("github");

GithubMessage = require("./github-message");

class Github extends Adapter
  constructor: (robot) ->
    super robot

  run: () ->
    self = @
    @.parseOptions()

    return console.error "No Github token provided to Hubot" unless @options.token

    @githubClient = new GitHubApi(version: "3.0.0")
    @githubClient.authenticate
      type: "oauth",
      token: @options.token

    # Initialize the webhook-listener
    @webhookListener = require('hubot-github-webhook-listener')(@robot)

    @robot.on "github-repo-event", (repo_event) =>

      githubPayload = repo_event.payload

      # Make sure we don't listen to our own messages
      switch(repo_event.eventType)
        when "issue_comment"
          return if @equalsRobotName(githubPayload.comment.user.login)

          # There are other types of comments we could respond to as well, but it gets complicated
          # For now, I just want to respond to comments in issues
          # "commit_comment", "pull_request_review_comment"
          action = githubPayload.action
          if action == "created"

            # Someone is chatting
            commentBody = githubPayload.comment.body

            author = self.getCommentAuthor githubPayload
            # Tell Hubot to associate this id with this user
            # Create a clone of the author
            author = Object.create(self.robot.brain.userForId author.id, author)
            # Everyone else uses a string to identify a room, so we will do the same thing
            # In our case, it's owner/repo/issue#
            issueNumber = @getIssueNumberFromPayload(githubPayload)
            author.room = "#{githubPayload.repository.owner.login}/#{githubPayload.repository.name}/#{issueNumber}"
            author.reply_to = author.room

            if commentBody and author
              # Pass to the robot
              # If a receiver wants to, they can differentiate GithubMessages by the presence of githubPayload
              self.receive new GithubMessage(author, commentBody, githubPayload.comment.id, githubPayload)


    # Tell Hubot we're connected so it can load scripts
    @robot.logger.info "GitHub adapter is up and running as ", self.robot.name
    self.emit "connected"

  send: (envelope, strings...) ->
    reply_to = envelope.reply_to || envelope.room

    if (!reply_to)
      strings.forEach (str) =>
        @robot.logger.info "Envelope is undefined, so I won't send this message anywhere: ", str
    else
      strings.forEach (str) =>
        # Is the whole string just a URL?
        # If so, just inline it
        str = @preProcessOutgoingString(str)
        # We need to extract the owner, repo, and issue number from the room string
        [owner, repo, issueNumber] = @parseRoomString(reply_to)
        @robot.logger.debug "Creating comment in #{reply_to}: ", str
        @createGithubComment(owner, repo, issueNumber, str)

  parseRoomString: (roomString) ->
    components = roomString.split('/')
    if (components.length != 3)
      throw new Error("Room strings must take the form owner/repo/issue_num")
    return components

  emote: (envelope, strings...) ->
    @send envelope, "* #{str}" for str in strings

  reply: (envelope, strings...) ->
    strings = strings.map (s) -> "@#{envelope.user.name}: #{s}"
    @send envelope, strings...

  parseOptions: ->
    @options =
      token : process.env.HUBOT_GITHUB_TOKEN

  createGithubComment: (user, repo, issueNumber, commentBody) =>
    @githubClient.issues.createComment {
      user: user,
      repo: repo,
      number: issueNumber,
      body: commentBody
    }, (err, res) =>
      if (err)
        @robot.logger.error "Couldn't make the github comment: #{err}", user, repo, issueNumber, commentBody

  getCommentAuthor: (data) ->
    # Return an author object
    id       : data.comment.user.id
    name     : data.comment.user.login

  preProcessOutgoingString: (str) ->
    # There are two things to do:
    # 1) Take all image URLS and make them inline
    # 2) Escape brackets like <this>
    # I've done 1, but not 2
    # There are fancier regexes to use, but I don't really care. All we really want to find are image URLs, or things that look an awful lot like them:
    # http://blah.blah.com/blah.png
    # An we'll turn that into ![](http://blah.blah.com/blah.png) so that Github displays it
    imageUrlRegex = /(https?:\/\/[\S]*\.(:?png|jpg|jpeg|gif))/gi;
    str = str.replace(imageUrlRegex, "![]($&)")
    str = str.replace(/</g, '&lt;')
    str = str.replace(/>/g, '&gt;')
    return str

  equalsRobotName: (str) ->
    return @getRegexForRobotName().test(str)

  getRegexForRobotName: () ->
    # This comes straight out of Hubot's Robot.coffee - they didn't get a nice way of extracting that method though
    if (!@cachedRobotNameRegex)
      name = @robot.name.replace(/[-[\]{}()*+?.,\\^$|#\s]/g, '\\$&')

      if @robot.alias
        alias = @robot.alias.replace(/[-[\]{}()*+?.,\\^$|#\s]/g, '\\$&')
        namePattern = "^\\s*[@]?(?:#{alias}|#{name})"
      else
        namePattern = "^\\s*[@]?#{name}"
      @cachedRobotNameRegex = new RegExp(namePattern, 'i')
    return @cachedRobotNameRegex

  getIssueNumberFromPayload: (payload) ->
    issueNumber = payload.issue?.number
    issueNumber ||= payload.pull_request?.number
    return issueNumber


exports.use = (robot) ->
  new Github robot

# SyncBranch

# POST /repos/:owner/:repo/merges

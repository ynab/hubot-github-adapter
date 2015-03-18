# hubot-github-adapter

A [Hubot](http://hubot.github.com/) adapter to use with [Github](http://github.com).

Use this adapter to have Hubot listen and comment on Github issues and pull requests.

## Motivation

We use pull requests a _lot_.
Now that we have a Hubot listening to our Pull Request chatter, we can do things like:

- Ask hubot to merge our target branch back into our feature branch
- Ask hubot to rebuild our branch (if it failed for a transient reason)
- Get a picture of a cool squirrel when we say "ship it"

So, basically all the cool stuff that Hubot already does, but in the context of Github comments.

## Getting Started

### Creating a new bot

Follow the [Hubot instructions](https://github.com/github/hubot/blob/master/docs/index.md) to create a new bot.

####Install this adapter:
- `cd /path/to/hubot`
- `yo hubot`
- `npm install hubot-github-adapter --save`
- Initialize git and make your initial commit

####Create a Github User for your bot:

This is the user your Hubot will use to post comments.

1. Sign up for a new account on [Github](https://github.com/)
2. If you have private repositories that your bot will be interacting with, [add your bot as a collaborator](https://help.github.com/articles/adding-collaborators-to-a-personal-repository/) to all of the repositories you want it to listen and respond to. You can skip this step for public repos.
3. [Create a new OAuth token for this Github User](https://help.github.com/articles/creating-an-access-token-for-command-line-use/). It needs the following scopes:

- repo (If you want it to create comments on private repos it has access to)
- public_repo (so that it can create comments on public repos)

(Keep this token as secret as you would a password.)

####Create a Github Webhook for your each of your repositories:

You'll need to create a Github webhook for every repository you want Hubot to listen to.

**SECURITY WARNING**: The [Github Webhook listener](https://github.com/ynab/hubot-github-webhook-listener) does not currently validate the Github Secret to verify that the webhook came from Github. So, if someone knows the URL to your Hubot, they can spoof webhooks and issue your Hubot commands. So, for now be careful about exposing commands like `destroy company`, etc.

1. Create a new webhook for your `myuser/myrepo` repository at:
   https://github.com/myuser/myrepo/settings/hooks/new
   Set the webhook url to: &lt;HUBOT_URL&gt;:&lt;PORT&gt;/hubot/github-repo-listener

   For example, if your hubot lives at myhubot.herokuapp.com, then you will set the webhook URL to: http://myhubot.herokuapp.com/hubot/github-repo-listener

   All of your repositories will point to the same URL.

####Configure your Hubot

Set the `HUBOT_GITHUB_TOKEN` environment variable to the token you created above.

Let's say you gave your Hubot user the name "BestHubotEver"
You'll want to start your hubot with that name:

- `HUBOT_GITHUB_TOKEN=some-long-guid-number ./bin/hubot --adapter github-adapter --name BestHubotEver`

####Test Your Hubot

Hubot is now listening to your comments on issues and pull requests.
You should be able to say:
`@BestHubotEver ping`, and if he is listening, he will respond with `PONG`

#### Testing your bot locally

If you want to test your bot locally, you can create a temporary webhook that goes to your machine instead of a live Hubot. See detailed instructions on the [hubot-github-webhook-listener](hubot-github-webhook-listener) page.

## Configuration

This adapter uses the following environment variables:

 - `HUBOT_GITHUB_TOKEN` - This is the auth token for the Github user you created above. Required for Hubot to comment on issues.


## Writing your own scripts

We've published an [example script](https://gist.github.com/Taytay/3cc046043f49d13c0a02) we use with this adapter to help us manage our Pull Requests.

### Responding to text commands

Nothing changes if you want to respond to text commands. It's just like any other Hubot adapter in that regard:
```coffeescript
robot.respond /hello/i, (response) ->
   response.send("Well hello to you too!")
robot.hear /YNAB/i, (response) ->
   response.send("Did someone mention YNAB? I love YNAB!")
```

### Events

This adapter guarantees that an event `github-repo-event` is emitted for every webhook received from Github. 
It has the following structure:
```coffeescript
eventBody =
        eventType   : req.headers["x-github-event"]
        signature   : req.headers["X-Hub-Signature"]
        deliveryId  : req.headers["X-Github-Delivery"]
        payload     : req.body
        query       : querystring.parse(url.parse(req.url).query)
```

And you can listen to it like so (taken from our [example script](https://gist.github.com/Taytay/3cc046043f49d13c0a02))

```coffeescript
  robot.on "github-repo-event", (repoEvent) =>

    # Note that this assumes you are using the Hubot Github adapter, because it tries to comment on a github issue like
    # user/repo/issueNumber
    # And that's only valid if you are using the github adapter.
    # https://github.com/ynab/hubot-github-adapter

    switch repoEvent.eventType
      when "pull_request"
        payload = repoEvent.payload
        if (payload.action == "opened")
          robot.send room: getRoomFromRepositoryAndIssue(payload), "I'm your friendly neighborhood Github robot, and I can help you with your pull requests. For a list of the things I can do, just write:\n@#{robot.name} help"
      when "status"
        payload = repoEvent.payload
        switch payload.state
          when "failure", "error" #success, failure, error
            # We can just comment on this failed commit:
            repoOwner = payload.repository.owner.login
            repoName = payload.repository.name
            # Merge commits have one extra commit inside the first one
            commitAuthor = payload.commit.author?.login || payload.commit.commit?.author.login
            githubClient.repos.createCommitComment {
              user: repoOwner,
              repo: repoName,
              sha: payload.commit.sha,
              commit_id: payload.commit.sha,
              body: "@#{commitAuthor}: It looks like the last build failed for this commit: [#{payload.description}](#{payload.target_url})"
            },  (err, success) ->
              if (err)
                robot.logger.error err
```
 
For more information, see:

1) [Hubot Github Webhook Listener](https://github.com/ynab/hubot-github-webhook-listener), the Hubot script that emits the event.
2) Our [example script](https://gist.github.com/Taytay/3cc046043f49d13c0a02)
3) [Github's documentation on webhooks](https://developer.github.com/webhooks/)

### Inline Images and other escaping

All messages you send through the Github adapter will have the following preprocessing performed:

1) All raw image URLs are converted to inline images:
For example, this: `https://octodex.github.com/images/hubot.jpg` gets converted into this:

`![](https://octodex.github.com/images/hubot.jpg)`

Which means you will actually see the image like so in Github comments: 
![](https://octodex.github.com/images/hubot.jpg)

(This hasn't been thoroughly tested, but we can confirm that `hubot mustache me`, `hubot image me squirrel`, and `ship it!` commands all work)

2) Brackets &lt; and &gt; are escaped into: `&lt;` and `&gt;` so that Hubot can display them.


## A note on naming

It's customary to name adapters simply `hubot-<adapter>`, however `hubot-github` is taken, so this is now `hubot-github-adapter`.

## Copyright

Copyright &copy; [YouNeedABudget.com](http://youneedabudget.com), LLC. (Github: [YNAB](http://github.com/ynab))

## Author

Taylor Brown, aka [Taytay](http://github.com/Taytay)

## License

MIT License; see LICENSE for further details.

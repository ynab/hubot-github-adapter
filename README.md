# hubot-slack

A [Hubot](http://hubot.github.com/) adapter to use with [Github](http://github.com).

Use this adapter to listen to Hubot commands from Github issues and pull requests.

## Motivation

We use pull requests a _lot_.
Now that we have a Hubot listening to our Pull Request chatter, we can do things like:

- Ask hubot to merge our target branch back into our feature branch
- Ask hubot to rebuild our branch (if it failed for a transient reason)
- Get a picture of a cool squirrel when we say "ship it"

So, basically all the cool stuff that Hubot already does, but in the context of Github comments.

## Getting Started

### Creating a new bot

Follow the (Hubot instructions)[https://github.com/github/hubot/blob/master/docs/index.md] to create a new bot.

####Install this adapter:
- `cd /path/to/hubot`
- `yo hubot`
- `npm install hubot-github --save`
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

1. Create a new webhook for your `myuser/myrepo` repository at:
   https://github.com/myuser/myrepo/settings/hooks/new
   Set the webhook url to: <HUBOT_URL>:<PORT>/hubot/github-repo-listener

   For example, if your hubot lives at myhubot.herokuapp.com, then you will set the webhook URL to: http://myhubot.herokuapp.com/hubot/github-repo-listener

   All of your repositories will point to the same URL.

####Configure your Hubot

Let's say you gave your Hubot user the name "BestHubotEver"
You'll want to start your hubot with that name:

- `HUBOT_GITHUB_TOKEN=some-long-guid-number ./bin/hubot --adapter github --name BestHubotEver`

####Test Your Hubot

Hubot is now listening to your comments on issues and pull requests.
You should be able to say:
`@BestHubotEver ping`, and if he is listening, he will respond with `PONG`

#### Testing your bot locally

If you want to test your bot locally, you can create a temporary webhook that goes to your machine instead of a live Hubot. See detailed instructions on the [hubot-github-webhook-listener](hubot-github-webhook-listener) page.

## Configuration

This adapter uses the following environment variables:

 - `HUBOT_GITHUB_TOKEN` - This is the auth token for the Github user you created above.

## Copyright

Copyright &copy; YouNeedABudget.com, LLC.

## Author

Taylor Brown, aka Taytay

## License

MIT License; see LICENSE for further details.

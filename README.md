# Twitter List Banner Maker

A Ruby script for generating a banner image for your Twitter lists with the profiles pics of the members of that list.

Like this:

![A list of Twitter avatars.](https://github.com/matthewl/TwitterListBannerMaker/blob/main/twitter_list_example.png?raw=true)


## Pre-requisites

You will need to create a project and an app in Twitter's Developer Portal. You will also generate an access token and secret within the your app to use with the script. You can find more information on doing this within the Developer Portal's [getting started](https://developer.twitter.com/en/docs/platform-overview) page.

The script uses Twitter's v2 of the API.

## Usage

Run `bundle install` to install dependent gems.

Run the ruby script with your app's access token and secret passed in as environment variables like so:

```shell
CONSUMER_KEY=PNxCNgyJeuLi7azqRyKco7qlm CONSUMER_SECRET=nSB5xz0WCYd0Ag1PeEDJ1oSIjxYDjl4akufww1o4lUqHatxXdm ruby app.rb
```

You'll be asked to authenticate your Twitter account against the application by visiting a URL on the Twitter API and entering a pin number.

Once authenticated, the script will display all your Twitter lists.

```shell
Welcome to TwitterListBannerMaker! 😀

Enter the number of the list you want to use for the banner :
-------------------------------------------------------------

1. Developers
2. Golf
3. NFL
4. Tools & Toys

Or enter 'q' to quit

List number:

```

Select the list you would like to generate an image for and it will be saved within the same directory as the script.

## License

The source code is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).


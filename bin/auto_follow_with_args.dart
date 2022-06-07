import 'package:batch/batch.dart';
import 'package:twitter_api_v2/twitter_api_v2.dart';

/// Run this application with command:
/// `dart run bin/auto_follow_with_args.dart -k YOUR_CONSUMER_KEY -c YOUR_CONSUMER_SECRET -t YOUR_TOKEN -s YOUR_SECRET`
void main(List<String> args) => BatchApplication(
      args: args,
      argsConfigBuilder: (parser) => parser
        ..addOption('apiBearerToken', abbr: 'b')
        ..addOption('apiConsumerKey', abbr: 'k')
        ..addOption('apiConsumerSecret', abbr: 'c')
        ..addOption('apiToken', abbr: 't')
        ..addOption('apiSecret', abbr: 's'),
      onLoadArgs: (args) {
        final twitter = TwitterApi(
          bearerToken: args['apiBearerToken'],

          // Or you can use OAuth 1.0a tokens.
          oauthTokens: OAuthTokens(
            consumerKey: args['apiConsumerKey'],
            consumerSecret: args['apiConsumerSecret'],
            accessToken: args['apiToken'],
            accessTokenSecret: args['apiSecret'],
          ),
        );

        // Add instance of TwitterApi to shared parameters.
        // This instance can be used from anywhere in this batch application as a singleton instance.
        return {'twitterApi': twitter};
      },
      jobs: [AutoFollowUserJob()],
    )..run();

class AutoFollowUserJob implements ScheduledJobBuilder {
  @override
  ScheduledJob build() => ScheduledJob(
        name: 'Auto Follow User Job',
        schedule: CronParser('* */1 * * *'), // Will be executed hourly
        steps: [
          Step(
            name: 'Auto Follow User Step',
            task: AutoFollowUserTask(),
          ),
        ],
      );
}

class AutoFollowUserTask extends Task<AutoFollowUserTask> {
  @override
  Future<void> execute(ExecutionContext context) async {
    // Get TwitterApi instance from shared parameters.
    final TwitterApi twitter = context.sharedParameters['twitterApi'];

    try {
      // You need your user id to create follow.
      final me = await twitter.usersService.lookupMe();
      // Search for tweets
      final tweets = await twitter.tweetsService.searchRecent(
        query: '#coding',
        tweetFields: [
          // Add author id field.
          TweetField.authorId,
        ],
      );

      int count = 0;
      for (final tweet in tweets.data) {
        if (count >= 3) {
          // Stop after 3 auto-follows
          return;
        }

        // Auto follow
        await twitter.usersService.createFollow(
          userId: me.data.id,
          targetUserId: tweet.authorId!,
        );

        count++;
      }
    } catch (e, s) {
      log.error('Failed to follow', e, s);
    }
  }
}

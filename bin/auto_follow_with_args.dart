import 'package:batch/batch.dart';
import 'package:dart_twitter_api/twitter_api.dart';

/// Run this application with command:
/// `dart run bin/auto_follow_with_args.dart -k YOUR_CONSUMER_KEY -c YOUR_CONSUMER_SECRET -t YOUR_TOKEN -s YOUR_SECRET`
void main(List<String> args) => BatchApplication(
      args: _argParser.parse(args),
      onLoadArgs: _onLoadArgs,
    )
      ..addJob(Job(
        name: 'Auto Follow User Job',
        schedule: CronParser(value: '*/1 * * * *'), // Will be executed hourly.
      )..nextStep(
          Step(name: 'Auto Follow User Step')
            ..registerTask(AutoFollowUserTask()),
        ))
      ..run();

ArgParser get _argParser => ArgParser()
  ..addOption('apiConsumerKey', abbr: 'k')
  ..addOption('apiConsumerSecret', abbr: 'c')
  ..addOption('apiToken', abbr: 't')
  ..addOption('apiSecret', abbr: 's');

Function(
    ArgResults args,
    void Function({required String key, required dynamic value})
        addSharedParameters) get _onLoadArgs => (args, addSharedParameters) {
      final twitter = TwitterApi(
        client: TwitterClient(
          consumerKey: args['apiConsumerKey'],
          consumerSecret: args['apiConsumerSecret'],
          token: args['apiToken'],
          secret: args['apiSecret'],
        ),
      );

      // Add instance of TwitterApi to shared parameters.
      // This instance can be used from anywhere in this batch application as a singleton instance.
      addSharedParameters(key: 'twitterApi', value: twitter);
    };

class AutoFollowUserTask extends Task<AutoFollowUserTask> {
  @override
  Future<void> execute(ExecutionContext context) async {
    // Get TwitterApi instance from shared parameters.
    final TwitterApi twitter = context.sharedParameters['twitterApi'];

    try {
      // Search for tweets
      final tweets =
          await twitter.tweetSearchService.searchTweets(q: '#programming');

      int count = 0;
      for (final status in tweets.statuses!) {
        if (count >= 3) {
          // Stop after 3 auto-follows
          return;
        }

        // Auto follow
        await twitter.userService.friendshipsCreate(userId: status.idStr!);
        count++;
      }
    } catch (e, s) {
      log.error('Failed to follow', e, s);
    }
  }
}

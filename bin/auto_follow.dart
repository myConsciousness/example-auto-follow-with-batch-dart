import 'package:batch/batch.dart';
import 'package:dart_twitter_api/twitter_api.dart';

void main(List<String> args) => BatchApplication()
  ..nextSchedule(AutoFollowUserJob())
  ..run();

class AutoFollowUserJob implements ScheduledJobBuilder {
  @override
  ScheduledJob build() => ScheduledJob(
        name: 'Auto Follow User Job',
        schedule: CronParser('* */1 * * *'), // Will be executed hourly
      )..nextStep(
          Step(
            name: 'Auto Follow User Step',
            task: AutoFollowUserTask(),
          ),
        );
}

class AutoFollowUserTask extends Task<AutoFollowUserTask> {
  @override
  Future<void> execute(ExecutionContext context) async {
    // You need to get your own API keys from https://apps.twitter.com/
    final twitter = TwitterApi(
      client: TwitterClient(
        consumerKey: 'Your consumer key',
        consumerSecret: 'Your consumer secret',
        token: 'Your token',
        secret: 'Your secret',
      ),
    );

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

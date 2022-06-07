import 'package:batch/batch.dart';
import 'package:twitter_api_v2/twitter_api_v2.dart';

void main(List<String> args) => BatchApplication(
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
          )
        ],
      );
}

class AutoFollowUserTask extends Task<AutoFollowUserTask> {
  @override
  Future<void> execute(ExecutionContext context) async {
    // You need to get your own tokens from https://apps.twitter.com/
    final twitter = TwitterApi(
      bearerToken: 'YOUR_BEARER_TOKEN_HERE',

      // Or you can use OAuth 1.0a tokens.
      oauthTokens: OAuthTokens(
        consumerKey: 'YOUR_API_KEY_HERE',
        consumerSecret: 'YOUR_API_SECRET_HERE',
        accessToken: 'YOUR_ACCESS_TOKEN_HERE',
        accessTokenSecret: 'YOUR_ACCESS_TOKEN_SECRET_HERE',
      ),
    );

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

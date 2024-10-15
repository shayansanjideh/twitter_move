/// Module that allows for a representation of a Twitter-like social media platform.
/// Users are able to create a profile, send Tweets, and like and reply to other Tweets

module twitter_move::twitter_move {

    // >>>>>>>> Imports <<<<<<<< 

    use aptos_std::table::{Self, Table};
    use aptos_framework::account;
    use aptos_framework::timestamp;
    use std::string::String;
    use std::signer;
    use std::vector;


    // >>>>>>>> Imports <<<<<<<< 

    // >>>>>>>> Errors <<<<<<<<

    const EPROFILE_DNE: u64 = 1;
    const EPROFILE_EXISTS: u64 = 2;


    // >>>>>>>> Errors <<<<<<<< 

    // >>>>>>>> Structs <<<<<<<< 

    /// One's profile
    struct Profile has key {
        user_address: address,
        username: String,
        bio: String,
        date_created: u64,
    }

    /// An individual Tweet
    struct Tweet has store, drop, copy {
        profile_username: String,
        time_posted: u64,
        tweet_content: String,
        likes: vector<address>,
    }

    /// All Tweets appear here
    struct Homepage has key {
        tweets: Table<u64, Tweet>,
        tweet_index: u64
    }

    // >>>>>>>> Structs <<<<<<<< 

    // >>>>>>>> Init Function <<<<<<<<

    /// Initializes the module. Creates a `Homepage`; without this, one cannot post Tweets.
    fun initalize(admin: &signer, seed: vector<u8>) {
        // in this particular example we do not need the resource signer capability (`resource_signer_cap`), so we prefix it with an underscore.
        // Otherwise, we would have to consume it before the function ends.
        let (resource_signer, _resource_signer_cap) = account::create_resource_account(admin, seed);

        // Here, resource_signer.address represents the location in global storage of the newly initialized Homepage
        // struct. This moves the Homepage struct into its newly generated account.
        move_to<Homepage>(
            &resource_signer,
            Homepage {
                tweets: table::new<u64, Tweet>(),
                tweet_index: 0,
            }
        );
    }

    // >>>>>>>> Init Function <<<<<<<<

    // >>>>>>>> Entry Functions <<<<<<<< 

    /// Creates a profile. One address can only have one profile.
    public entry fun create_profile(user: &signer, username: String, bio: String) {
        let user_address = signer::address_of(user);
        // assert that the profile does not already exist
        assert!(!exists<Profile>(user_address), EPROFILE_EXISTS);

        move_to<Profile>(
            user,
            Profile {
                user_address,
                username,
                bio,
                date_created: timestamp::now_seconds(),

            }
        );
    }

    /// Creates a Tweet and posts it to the `Homepage`
    public entry fun create_tweet(user: &signer, tweet_content: String, homepage_resource_addr: address,) acquires Homepage, Profile {
        let user_address = signer::address_of(user);
        assert!(exists<Profile>(user_address), EPROFILE_DNE);

        let profile = borrow_global<Profile>(user_address);

        let tweet = Tweet {
            profile_username: profile.username,
            time_posted: timestamp::now_seconds(),
            tweet_content,
            likes: vector::empty(),
        };

        let homepage = borrow_global_mut<Homepage>(homepage_resource_addr);
        let tweet_index = homepage.tweet_index + 1;

        table::add(&mut homepage.tweets, tweet_index, tweet);
    }

    public entry fun like_tweet(user: &signer, homepage_resource_addr: address, tweet_index: u64) acquires Homepage {
        let user_address = signer::address_of(user);
        let homepage = borrow_global_mut<Homepage>(homepage_resource_addr);
        let tweet = table::borrow_mut(&mut homepage.tweets, tweet_index);
        vector::push_back<address>(&mut tweet.likes, user_address);

    }
    // >>>>>>>> Entry Functions <<<<<<<< 

}
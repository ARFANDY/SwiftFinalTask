//
//  main.swift
//  FirstCourseFinalTask
//
//  Copyright © 2017 E-Legion. All rights reserved.
//

import Foundation
import FirstCourseFinalTaskChecker

class Post: PostProtocol {
    internal init(
        id: Post.Identifier,
        author: GenericIdentifier<UserProtocol>,
        description: String,
        imageURL: URL,
        createdTime: Date,
        likes: [(GenericIdentifier<UserProtocol>, GenericIdentifier<PostProtocol>)],
        currentUserID: GenericIdentifier<UserProtocol>
    ) {
        self.id = id
        self.author = author
        self.description = description
        self.imageURL = imageURL
        self.createdTime = createdTime
        self.likes = likes
        self.currentUserID = currentUserID
    }
    
    var id: Identifier
    var author: GenericIdentifier<UserProtocol>
    var description: String
    var imageURL: URL
    var createdTime: Date
    var currentUserLikesThisPost: Bool { likes.contains { $0 == (currentUserID, id) } }
    var likedByCount: Int { likes.filter { $0.1 == id }.count }
    
    var likes: [(GenericIdentifier<UserProtocol>, GenericIdentifier<PostProtocol>)]
    var currentUserID: GenericIdentifier<UserProtocol>
    
    func updateLikes(
        with likes: [(GenericIdentifier<UserProtocol>, GenericIdentifier<PostProtocol>)]
    ) {
        self.likes = likes
    }
}

class PostsStorage: PostsStorageProtocol {
    var count: Int
    var currentUserID: GenericIdentifier<UserProtocol>
    var likes: [(GenericIdentifier<UserProtocol>, GenericIdentifier<PostProtocol>)]
    var postsWithProtocol: [PostProtocol] = []
    
    required init(
        posts: [PostInitialData],
        likes: [(GenericIdentifier<UserProtocol>, GenericIdentifier<PostProtocol>)],
        currentUserID: GenericIdentifier<UserProtocol>
    ) {
        self.count = posts.count
        self.currentUserID = currentUserID
        self.likes = likes
        
        posts.forEach { post in
            postsWithProtocol.append(
                Post(
                    id: post.id,
                    author: post.author,
                    description: post.description,
                    imageURL: post.imageURL,
                    createdTime: post.createdTime,
                    likes: likes,
                    currentUserID: currentUserID
                )
            )
        }
    }
    
    func post(
        with postID: GenericIdentifier<PostProtocol>
    ) -> PostProtocol? {
        postsWithProtocol.first { $0.id == postID }
    }
    
    func findPosts(
        by authorID: GenericIdentifier<UserProtocol>
    ) -> [PostProtocol] {
        postsWithProtocol.filter { $0.author == authorID }
    }
    
    func findPosts(
        by searchString: String
    ) -> [PostProtocol] {
        postsWithProtocol.filter { $0.description.contains(searchString) }
    }
    
    func likePost(
        with postID: GenericIdentifier<PostProtocol>
    ) -> Bool {
        guard postsWithProtocol.contains(where: {$0.id == postID}) else { return false }
        guard !likes.contains(where: {$0 == (currentUserID, postID)}) else { return true }
        
        likes.append((currentUserID, postID))
        
        if let post = postsWithProtocol.first(where: { $0.id == postID }) as? Post {
            post.updateLikes(with: likes)
        }
        return true
    }
    
    func unlikePost(
        with postID: GenericIdentifier<PostProtocol>
    ) -> Bool {
        guard postsWithProtocol.contains(where: { $0.id == postID }) else { return false }
        
        likes.removeAll { $0 == (currentUserID, postID) }
        
        if let post = postsWithProtocol.first(where: { $0.id == postID }) as? Post {
            post.updateLikes(with: likes)
        }
        return true
    }
    
    func usersLikedPost(
        with postID: GenericIdentifier<PostProtocol>
    ) -> [GenericIdentifier<UserProtocol>]? {
        guard postsWithProtocol.contains(where: { $0.id == postID }) else { return nil }
        return likes.filter { $0.1 == postID }.compactMap { $0.0 }
    }
}

class User: UserProtocol {
    internal init(
        id: User.Identifier,
        username: String,
        fullName: String,
        avatarURL: URL? = nil,
        followers: [(GenericIdentifier<UserProtocol>, GenericIdentifier<UserProtocol>)],
        currentUserID: GenericIdentifier<UserProtocol>
    ) {
        self.id = id
        self.username = username
        self.fullName = fullName
        self.avatarURL = avatarURL
        self.followers = followers
        self.currentUserID = currentUserID
    }
    
    var id: Identifier
    var username: String
    var fullName: String
    var avatarURL: URL?
    var currentUserFollowsThisUser: Bool { followers.contains { $0 == (currentUserID, id) } }
    var currentUserIsFollowedByThisUser: Bool { followers.contains { $0 == (id, currentUserID) } }
    var followsCount: Int { followers.filter { $0.0 == id }.count }
    var followedByCount: Int { followers.filter { $0.1 == id }.count }
    
    var followers: [(GenericIdentifier<UserProtocol>, GenericIdentifier<UserProtocol>)]
    var currentUserID: GenericIdentifier<UserProtocol>
    
    func updateFollowers(
        with followers: [(GenericIdentifier<UserProtocol>, GenericIdentifier<UserProtocol>)]
    ) {
        self.followers = followers
    }
}

class UsersStorage: UsersStorageProtocol {
    var count: Int
    let currentUserID: GenericIdentifier<UserProtocol>
    var followers: [(GenericIdentifier<UserProtocol>, GenericIdentifier<UserProtocol>)]
    var usersWithProtocol: [UserProtocol] = []

    required init?(
        users: [UserInitialData],
        followers: [(GenericIdentifier<UserProtocol>, GenericIdentifier<UserProtocol>)],
        currentUserID: GenericIdentifier<UserProtocol>
    ) {
        guard users.contains(where: { $0.id == currentUserID }) else { return nil }

        self.count = users.count
        self.currentUserID = currentUserID
        self.followers = followers

        users.forEach { user in
            usersWithProtocol.append(
                User(
                    id: user.id,
                    username: user.username,
                    fullName: user.fullName,
                    avatarURL: user.avatarURL,
                    followers: followers,
                    currentUserID: currentUserID
                )
            )
        }
    }

    func currentUser() -> UserProtocol {
        usersWithProtocol.filter { $0.id == currentUserID }[0]
    }

    func user(
        with userID: GenericIdentifier<UserProtocol>
    ) -> UserProtocol? {
        usersWithProtocol.first { $0.id == userID }
    }

    func findUsers(
        by searchString: String
    ) -> [UserProtocol] {
        usersWithProtocol.filter { $0.fullName.contains(searchString) || $0.username.contains(searchString) }
    }

    func follow(
        _ userIDToFollow: GenericIdentifier<UserProtocol>
    ) -> Bool {
        guard usersWithProtocol.contains(where: { $0.id == userIDToFollow }) else { return false }
        guard !followers.contains(where: { $0 == (currentUserID, userIDToFollow) }) else { return true }

        followers.append((currentUserID, userIDToFollow))

        if let user = usersWithProtocol.first(where: { $0.id == userIDToFollow }) as? User {
            user.updateFollowers(with: followers)
        }
        
        if let user = usersWithProtocol.first(where: { $0.id == currentUserID }) as? User {
            user.updateFollowers(with: followers)
        }

        return true
    }

    func unfollow(
        _ userIDToUnfollow: GenericIdentifier<UserProtocol>
    ) -> Bool {
        guard usersWithProtocol.contains(where: { $0.id == userIDToUnfollow }) else { return false }
        followers.removeAll { $0 == (currentUserID, userIDToUnfollow) }

        if let user = usersWithProtocol.first(where: { $0.id == userIDToUnfollow }) as? User {
            user.updateFollowers(with: followers)
        }
        
        if let user = usersWithProtocol.first(where: { $0.id == currentUserID }) as? User {
            user.updateFollowers(with: followers)
        }

        return true
    }

    func usersFollowingUser(
        with userID: GenericIdentifier<UserProtocol>
    ) -> [UserProtocol]? {
        guard usersWithProtocol.contains(where: { $0.id == userID }) else { return nil }
        var listOfFollowers: [UserProtocol] = []
        
        followers.forEach { follower in
            if follower.1 == userID,
               let user = usersWithProtocol.first(where: { $0.id == follower.0 }) {
                listOfFollowers.append(user)
            }
        }
        
        return listOfFollowers
    }

    func usersFollowedByUser(
        with userID: GenericIdentifier<UserProtocol>
    ) -> [UserProtocol]? {
        guard usersWithProtocol.contains(where: { $0.id == userID }) else { return nil }
        
        var listOfFollowers: [UserProtocol] = []
        
        followers.forEach { follower in
            if follower.0 == userID,
               let user = usersWithProtocol.first(where: { $0.id == follower.1 }) {
                listOfFollowers.append(user)
            }
        }
        
        return listOfFollowers
    }
}

let checker = Checker(
    usersStorageClass: UsersStorage.self,
    postsStorageClass: PostsStorage.self
)
checker.run()


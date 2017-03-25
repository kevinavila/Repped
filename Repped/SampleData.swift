//
//  SampleData.swift
//  Repped
//
//  Created by Wes Draper on 3/24/17.
//  Copyright © 2017 Audiophiles. All rights reserved.
//

import Foundation
import Firebase


class SampleData {
    
    private lazy var roomRef:FIRDatabaseReference = FIRDatabase.database().reference().child("rooms")
    private lazy var userRef:FIRDatabaseReference = FIRDatabase.database().reference().child("users")
    private lazy var joinRef:FIRDatabaseReference = FIRDatabase.database().reference().child("joinTable")
    private var userList:[User] = [User]()
    
    static let sharedSample = SampleData()
    
    public let testFriendList: [String:String] =  [
        "10152711615419090": "Jonathon Chu",
        "712538729": "Will Siegfried",
        "766308634": "Alvin Qicong Deng",
        "1007085677": "Taylor Levesque",
        "1553550286": "Andrew McDonald",
        "875928805754296": "Peter Ten Eyck",
        "100001971649787": "Frank Long",
        ]
    
    
    private func addUserToFireBase(_ user: User){
        let newUser = [
            "name": user.name,
            "email": user.email,
            "rep": user.rep,
            "id": user.uid,
            "friends": user.friendList,
            ] as [String:Any]
        self.userRef.child(user.uid).setValue(newUser)
    }
    
    private func makeUsersFromSampleUsers(){
        let data:[[String:String]] =  [
            ["id": "10152711615419090", "name": "Jonathon Chu"],
            ["id": "712538729", "name": "Will Siegfried"],
            ["id": "766308634", "name": "Alvin Qicong Deng"],
            ["id": "1007085677", "name": "Taylor Levesque"],
            ["id": "1553550286", "name": "Andrew McDonald"],
            ["id": "875928805754296", "name": "Peter Ten Eyck"],
            ["id": "100001971649787", "name": "Frank Long"],
            ]
        for entry in data {
            let newUser = User(uid: entry["id"]!, name: entry["name"]!)
            newUser.email = "fake@mail.com"
            newUser.rep = Int(arc4random_uniform(50))
            newUser.friendList = self.testFriendList
            self.userList.append(newUser)
        }

    }
    
    private func makeRoomWithLeader(_ leader: User) -> String {
        let newRoomRef = self.roomRef.childByAutoId()
        let roomItem = [
            "name": leader.name + "\'s Room",
            "leader": leader.uid
            ] as [String:Any]
        //Add Room With user as leader
        newRoomRef.setValue(roomItem)
        
        //Add user and room to join table
        self.joinRef.child(leader.uid).setValue(newRoomRef.key)
        
        return newRoomRef.key
    }
    
    private func addUserToRoom(_ user: User, rid: String){
        self.joinRef.child(user.uid).setValue(rid)
    }
    
    
    public func makeSampleUsers(){
        makeUsersFromSampleUsers()
        for user in self.userList {addUserToFireBase(user)}
        
        let rid1 = makeRoomWithLeader(self.userList[0])
        for index in 1...2 {
            addUserToRoom(self.userList[index], rid: rid1)
        }
        
        let rid2 = makeRoomWithLeader(self.userList[3])
        for index in 4...5 {
            addUserToRoom(self.userList[index], rid: rid2)
        }
    }
    
    public func addUserToMyRoom(_ rid: String){
        for index in 6...6 {
            addUserToRoom(self.userList[index], rid: rid)
        }
    }
    
    
   }


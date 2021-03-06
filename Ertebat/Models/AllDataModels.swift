//
//  AllDataModels.swift
//  Ertebat
//
//  Created by Farid Rahmani on 2/9/18.
//  Copyright © 2018 Farid Rahmani. All rights reserved.
//

import Foundation

enum PostType{
    case text
    case picture
    case video
}


@objcMembers class Post:NSObject {
    var postId:String?
    var type:PostType?
    var pictureUrl: String?
    var videoUrl: String?
    var text:String?
    var authorId:String?
    var date:NSDate?
    var imageWidth:Int?
    var imageHeight:Int?
    dynamic var imageDownloaded = false
    dynamic var percentImageDownloaded:Float = 0
    dynamic var image:UIImage?
    init(type:PostType? = PostType.text, date:NSDate?, authorId:String?, text:String?, pictureUrl:String?, videoUrl:String?, imageWidth:Int?, imageHeight:Int?) {
        self.type = type
        self.date = date
        self.authorId = authorId
        self.text = text
        self.pictureUrl = pictureUrl
        self.videoUrl = videoUrl
        self.imageWidth = imageWidth
        self.imageHeight = imageHeight
    }
    
    static func createWith(data:[String: Any]) -> Post{
        let post = Post(type: data["type"] as? PostType, date: data["date"] as? NSDate, authorId: data["authorId"] as? String, text: data["text"] as? String, pictureUrl: data["pictureUrl"] as? String, videoUrl: data["videoUrl"] as? String, imageWidth:data["imageWidth"] as? Int, imageHeight:data["imageHeight"] as? Int)
        post.downloadMedia()
        return post
    }
    var imageDownloadError = false
    func downloadMedia() {
        guard let imageUrlString = self.pictureUrl, let url = URL(string: imageUrlString) else{
            return
        }
        
        SDWebImageDownloader.shared().downloadImage(with: url, options: SDWebImageDownloaderOptions.continueInBackground, progress: { (downloaded, remaining, url) in
            DispatchQueue.main.async {
                self.percentImageDownloaded = Float(100 * downloaded / remaining)
                //print("\(100 * downloaded / remaining)")
            }
        }) { (img, data, err, completed) in
            DispatchQueue.main.async {
                if err != nil {
                    self.imageDownloadError = true
                    print("Error downloading profile image")
                }
                if let image = img{
                    self.image = image
                    self.imageDownloaded = true
                    print("Completed profile download successfully")
                }
            }
        }
        
    }
}



@objcMembers class User:NSObject{
    dynamic var name: String?
    var profileUrl: String?
    var id: String?
    dynamic var profileImage:UIImage?
    
    override func isEqual(_ object: Any?) -> Bool {
        if let other = object as? User, other.id == self.id{
            return true
        }
        return false
    }
    init(name:String?, profileUrl:String?, id:String?){
        self.name = name
        self.id = id
        self.profileUrl = profileUrl
        super.init()
        
    }
    func startDownloadingData() {
        downloadProfileImage()
        startObservering()
    }
    
    var alreadyObserving = false
    var observer:ListenerRegistration?
    func startObservering() {
        if let userId = id, alreadyObserving == false{
            alreadyObserving = true
            observer = Firestore.firestore().collection("users").document(userId).addSnapshotListener({ (ss, err) in
                if let error = err{
                    print(error.localizedDescription)
                }
                
                if let snapshot = ss{
                    if let data = snapshot.data(){
                        print("User info changed. Data: \(data)")
                        self.name = data["name"] as? String
                        if self.profileUrl != data["profileURL"] as? String{
                            self.profileUrl = data["profileURL"] as? String
                            self.downloadProfileImage()
                        }
                        
                    }
                    
                }
            })
        }
    }
    var profileImageDownloadError = false
    func downloadProfileImage(){
        if profileUrl == nil{
            return
        }
        let url = URL(string:profileUrl!)
        SDWebImageDownloader.shared().downloadImage(with: url, options: SDWebImageDownloaderOptions.continueInBackground, progress: { (downloaded, remaining, url) in
            DispatchQueue.main.async {
//                self.profilePicPercent = Float(100 * downloaded / remaining)
//                print("\(100 * downloaded / remaining)")
            }
        }) { (img, data, err, completed) in
            DispatchQueue.main.async {
                if err != nil {
                    self.profileImageDownloadError = true
                    print("Error downloading profile image")
                }
                if let image = img{
                    self.profileImage = image
                    print("Completed profile download successfully")
                }
            }
        }
    }
    
    func stopObserving(){
        observer?.remove()
        alreadyObserving = false
    }
    static func createWith(data:[String : Any]) -> User{
        return User(name: data["name"] as? String, profileUrl: data["profileURL"] as? String, id: data["id"] as? String)
    }
    
}



enum MessageType: Int{
    case text
    case picture
}



struct Message:Comparable{
    static func <(lhs: Message, rhs: Message) -> Bool {
        if let left = lhs.date, let right = rhs.date{
            return left < right
        }
        return false
    }
    
    static func ==(lhs: Message, rhs: Message) -> Bool {
        if let left = lhs.date, let right = rhs.date{
            return left == right
        }
        return false
    }
    var id:String?
    var type:String?
    var senderId:String?
    var receiverId:String?
    var text:String?
    var pictureUrl:String?
    var date:Date?
    var seen:Bool?
    func data() -> [String:Any] {
        return ["id": id!, "type": type ?? "", "senderId": senderId ?? "", "receiverId": receiverId ?? "", "text": text ?? "", "pictureUrl": pictureUrl ?? "", "date": date ?? "", "seen":seen ?? false]
    }
    
    static func initWithData(_ data:[String: Any])-> Message{
        
        return Message(id: data["id"] as? String, type: data["type"] as? String, senderId: data["senderId"] as? String, receiverId: data["receiverId"] as? String, text: data["text"] as? String, pictureUrl: data["pictureUrl"] as? String, date: data["date"] as? Date, seen: data["seen"] as? Bool)
    }
    
    init(id:String?, type:String?, senderId:String?, receiverId:String?, text:String?, pictureUrl:String?, date:Date?, seen:Bool?) {
        self.id = id
        self.type = type
        self.senderId = senderId
        self.receiverId = receiverId
        self.text = text
        self.pictureUrl = pictureUrl
        self.date = date
        self.seen = seen
    }
    
    init(type: String?, senderId: String?, receiverId: String?, text:String?, pictureUrl: String?) {
        self.id = UUID().uuidString
        self.type = type
        self.senderId = senderId
        self.receiverId = receiverId
        self.text = text
        self.pictureUrl = pictureUrl
        self.date = Date()
        self.seen = false
    }
    
    
    
    
}

struct Thread{
    var id:String
    var lastMessage:Message?
    var users:[String]?
    
    static func initWith(data:[String:Any])-> Thread{
        let lastMessageData = (data["lastMessage"] as? [String:Any]) ?? [String:Any]()
        let lastMessage = Message.initWithData(lastMessageData)
        return Thread(id: data["id"] as! String, lastMessage: lastMessage, users: data["users"] as? [String])
    }
    
    func data() -> [String: Any] {
        return ["id": id, "lastMessage": lastMessage ?? "", "users": users ?? ""]
    }
    
}
import Firebase
import FirebaseStorageUI
@objcMembers class ChatsCellData:NSObject{
//    static func <(lhs: ChatsCellData, rhs: ChatsCellData) -> Bool {
//        return lhs.lastMessage.date! < rhs.lastMessage.date!
//    }
//
//    static func ==(lhs: ChatsCellData, rhs: ChatsCellData) -> Bool {
//        return lhs.thread.id == rhs.thread.id
//    }
    override func isEqual(_ object: Any?) -> Bool {
      
        if let obj = object as? ChatsCellData, obj.thread.id == self.thread.id{
            return true
        }
        return false
    }
    var user:User
    var lastMessage:Message
    var thread:Thread
    var profilePic:UIImage?
    dynamic var unseenMessages = 0
    dynamic var downloaded = false
    dynamic var profilePicPercent:Float = 0
    init(user: User, lastMessage:Message, thread:Thread) {
        
        self.user = user
        self.thread = thread
        self.lastMessage = lastMessage
        super.init()
    }
    static func initWith(thread:Thread)-> ChatsCellData{
        let user = User(name: nil, profileUrl: nil, id: nil)
        let lastMessage = Message(id: nil, type: nil, senderId: nil, receiverId: nil, text: nil, pictureUrl: nil, date: Date(), seen: nil)
        let data = ChatsCellData(user: user, lastMessage: lastMessage, thread: thread)
       
        return data
    }
    
    func beginDownloading() {
        let users = thread.users!
        var userId = ""
        for id in users{
            if id != Auth.auth().currentUser!.uid{
                userId = id
            }
        }
        
        Firestore.firestore().collection("users").document(userId).addSnapshotListener({ (ss, err) in
            if let error = err{
                print(error.localizedDescription)
            }
            
            if let snapshot = ss{
                if let data = snapshot.data(){
                    self.user = User.createWith(data: data)
                    self.downloadProfileImage()
                    //Download last thread message
                    Firestore.firestore().collection("threads").document(self.thread.id).collection("messages").order(by: "date", descending: true).limit(to: 1).addSnapshotListener({ (ss, err) in
                        if let error = err{
                            print("Error Downloading last message:")
                            print(error.localizedDescription)
                        }
                        
                        if let snapshot = ss{
                            var data = [String:Any]()
                            if let doc = snapshot.documents.last{
                                data = doc.data()
                            }
                            self.lastMessage = Message.initWithData(data)
                            self.downloaded = true
                        }
                        Firestore.firestore().collection("threads").document(self.thread.id).collection("messages").whereField("senderId", isEqualTo:userId ).whereField("seen", isEqualTo:false).getDocuments(completion: { (ss, err) in
                            if let error = err{
                                print(error.localizedDescription)
                            }
                            if let snapshot = ss{
                               
                                if self.unseenMessages != snapshot.documents.count{
                                   self.unseenMessages = snapshot.documents.count
                                    var notification = Notification(name: Notification.Name(rawValue: "UnseenMessageNumberChange"))
                                    notification.userInfo = ["threadId": self.thread.id, "unseenMessages": self.unseenMessages]
                                    NotificationCenter.default.post(notification)
                                }
                                
                            }
                        })
                    })
                }
                
            }
        })
    }
    var profileImageDownloadError = false
    func downloadProfileImage(){
        guard let imageUrl = self.user.profileUrl, let url = URL(string:imageUrl) else {
            return
        }
//        SDWebImageManager.shared().loadImage(with: url, options: SDWebImageOptions.continueInBackground, progress: { (downloaded, remaining, url) in
//
//        }) { (img, data, err, cachType, bool, url) in
//
//
//        }
        
        SDWebImageDownloader.shared().downloadImage(with: url, options: SDWebImageDownloaderOptions.continueInBackground, progress: { (downloaded, remaining, url) in
            DispatchQueue.main.async {
                self.profilePicPercent = Float(100 * downloaded / remaining)
                //print("\(100 * downloaded / remaining)")
            }
        }) { (img, data, err, completed) in
            DispatchQueue.main.async {
                if err != nil {
                    self.profileImageDownloadError = true
                    print("Error downloading profile image")
                }
                if let image = img{
                    self.profilePic = image
                    print("Completed profile download successfully")
                }
            }
        }
        
        
        
    
    }
}

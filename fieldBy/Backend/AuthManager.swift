//
//  AuthManager.swift
//  fieldBy
//
//  Created by 박진서 on 2022/05/03.
//

import RxSwift
import RxCocoa
import NSObject_Rx
import Alamofire
import Firebase
import FirebaseStorage

class AuthManager: CommonBackendType {
    static let shared = AuthManager()
    
    var myUserModel: MyUserModel!

    var mainTabBar: MainTabBarController!
    
    var fcmToken: String?
    var fbToken: String!
    var userUUID: String!  //MARK: TODO - 지울것
    static let certificatedNumberPath = "/certificatedNumberList"
    static private let addressKey = "U01TX0FVVEgyMDIyMDUwMzE3MjM0NDExMjUzMDc="
    
    let igValidSubject = BehaviorSubject<Bool>(value: false)
    
    var defaultVC: DefaultViewController!
    
    func setToken(token: String) {
        self.fcmToken = token
    }
    
    func fetch(uuid: String) -> Completable {
        return Completable.create() { [unowned self] completable in
            ref.child("users").child(uuid)
                .observeSingleEvent(of: .value) { [unowned self] dataSnapShot in
                    if dataSnapShot.exists() {
                        if let myUserModel = MyUserModel(data: dataSnapShot) {
                            self.myUserModel = myUserModel
                            print(myUserModel.name)
                            if let fcmToken = fcmToken {
                                NotiManager.shared.setToken(token: fcmToken)
                            }
                            igValidSubject.onNext(myUserModel.igModel != nil)
                            completable(.completed)
                        } else {
                            completable(.error(FetchError.decodingFailed))
                        }
                    } else {
                        completable(.error(FetchError.emptyData))
                    }
                    

                }
            
            return Disposables.create()
        }
    }
    
    func addIGInfo(igModel: IGModel) {
        myUserModel.igModel = igModel
        igValidSubject.onNext(true)
        Database.database().reference().child("users/\(myUserModel.uuid!)/igInfo")
            .setValue(["id": igModel.id,
                       "name": igModel.name,
                       "username": igModel.username,
                       "token": igModel.token!,
                       "followers": igModel.followers,
                       "follows": igModel.follows,
                       "mediaCount": igModel.mediaCount])
        let imageRef = storageRef.child("userImages/\(myUserModel.uuid!)/profile.png")

        if let url = igModel.profileUrl {
            print("url")
            let data = try! Data(contentsOf: URL(string: url)!)
            let _ = imageRef.putData(data, metadata: nil) { metadata, error in
              guard let _ = metadata else {
                  print("에러")
                  print(error)
                return
              }

              imageRef.downloadURL { [unowned self] (url, error) in
                guard let downloadURL = url else {
                  print("URL 에러")
                  return
                }
                  Database.database().reference().child("users/\(myUserModel.uuid!)/igInfo")
                      .child("profileUrl").setValue(downloadURL.absoluteString)
              }
            }
        }
        

    }
    
    //MARK: TODO - 고칠 것
    func checkNumberValid(number: String) -> Observable<Bool> {
        return Observable.create() { [unowned self] observable in
            
            ref.child("certificatedNumberList").child(number)
                .observeSingleEvent(of: .value) { data in
                    if let bool = data.value as? Bool {
                        observable.onNext(bool)
                    } else {
                        observable.onNext(false)
                    }
                    
                }
            return Disposables.create()
            
        }
    }
    
    func addCampaign(uuid: String, size: String?, color: String?) {
        myUserModel.campaignUuids[uuid] = true
        myUserModel.campaigns.append(UserCampaignModel(uuid: uuid, size: size, color: color))
    }
    
    func removeCampaign(uuid: String, completion: @escaping (() -> Void)) {
        myUserModel.campaignUuids[uuid] = nil
        if let idx = myUserModel.campaigns.firstIndex(where: {$0.uuid == uuid}) {
            myUserModel.campaigns.remove(at: idx)
        }
        ref.child("users").child(myUserModel.uuid!).child("campaigns").child(uuid).removeValue { _, _ in
            completion()
        }
    }
    
    func bestImages(urls: [String]) {
        for i in 0..<3 {
            ref.child("users").child(myUserModel.uuid).child("bestImages").child("\(i)").setValue(urls[i])

        }
    }
    
    func refreshToken(token: String) {
        myUserModel.igModel?.token = token
        ref.child("users").child(myUserModel.uuid).child("igInfo").child("token").setValue(token)
    }
    
    func fetchCampaigns() -> Completable {
        return Completable.create() { [unowned self] completable in
            
            var temp = [UserCampaignModel]()
            var temp2 = [String: Bool]()
            
            ref.child("users").child(myUserModel.uuid).child("campaigns")
                .observeSingleEvent(of: .value) { [unowned self] snapshot in
                    for campaignSnapshot in snapshot.children.allObjects as! [DataSnapshot] {
                        if let model = UserCampaignModel(snapshot: campaignSnapshot) {
                            temp2[model.uuid] = true
                            temp.append(model)
                        }
                        
                    }
                    myUserModel.campaigns = temp
                    myUserModel.campaignUuids = temp2
                    
                    completable(.completed)
                    
                }
            
            
            
            return Disposables.create()
        }

    }
    
    
    static func address(keyword: String) -> Single<JusoResponse> {
        return Single.create() { observable in
            let addressBaseUrl = "https://www.juso.go.kr/addrlink/addrLinkApi.do"
            let params: [String: Any] = ["confmKey": addressKey,
                                                "currentPage": "1",
                                                "countPerPage":"30",
                                                "keyword": keyword,
                                                "resultType": "json"]
            
            AF.request(addressBaseUrl, method: .get, parameters: params).responseJSON { response in
                
                if let value = response.value {
                    if let jusoResponse: JusoResponse = self.toJson(object: value) {
                        observable(.success(jusoResponse))
                    } else {
//                        observable(.error())
                        print("serialize error")
                    }
                }
            }

            return Disposables.create()
        }
    }
    
    static func saveUserInfo(key: String, value: Any) {
        let uid = Auth.auth().currentUser!.uid
        Database.database().reference().child("users").child(uid).child("uid").setValue(uid)
        voidPost(path: "users/\(uid)", key: key, value: value)
    }
    
    static func saveInfo(key: String, value: Any) -> Completable {
        return simplePost(path: "/users/\(AuthManager.shared.userUUID!)/\(key)", body: value)
    }
    
    static func saveAddressInfo(juso: Juso, detail: String) {
        if let myUserModel = AuthManager.shared.myUserModel {
            myUserModel.juso = juso
            myUserModel.juso.detail = detail
            
            Database.database().reference().child("users").child(AuthManager.shared.myUserModel.uuid).child("address").setValue(["zipNo": juso.zipNo, "roadAddr": juso.roadAddr, "jibunAddr": juso.jibunAddr])
            Database.database().reference().child("users").child(AuthManager.shared.myUserModel.uuid).child("address/detail").setValue(detail)
        } else {
            Database.database().reference().child("users").child(AuthManager.shared.userUUID).child("address").setValue(["zipNo": juso.zipNo, "roadAddr": juso.roadAddr, "jibunAddr": juso.jibunAddr])
            Database.database().reference().child("users").child(AuthManager.shared.userUUID).child("address/detail").setValue(detail)
            Database.database().reference().child("users").child(AuthManager.shared.userUUID).child("reward").setValue("0")
        }

    }
    
    static func fetchUserInfo() -> Observable<Bool> {
        Observable.create() { observable in
            
            observable.onNext(true)
            
            
            return Disposables.create()
        }
    }
    
    static func fbPage() {
        
        //https://graph.instagram.com/refresh_access_token
        //?grant_type=ig_refresh_token
        //&access_token={단기토큰}
        
        
//        let path = "https://graph.facebook.com/v13.0/me?access_token=\(MyUserModel.shared.token)"
        
//        let path = "https://graph.facebook.com/\(MyUserModel.shared.faceId)?fields=id,name,email,picture&access_token=\(MyUserModel.shared.token)"
//        let path = "https://graph.instagram.com/refresh_access_token?grant_type=ig_refresh_token&access_token=\(MyUserModel.shared.igToken)"
//        let path = "https://graph.instagram.com/me?fields=id,caption&access_token=\(MyUserModel.shared.longToken)"
        let path = "https://api.instagram.com/oauth/authorize?"
        
        
//        let path = "https://graph.facebook.com/v13.0/\(MyUserModel.shared.faceId)?fields=instagram_business_account&access_token=\(MyUserModel.shared.token)"

        
        AF.request(path, method: .get)
            .responseString { response in
                switch response.result {
                case .success(let str):
                    
                    print(str)
                    
                    
                    
                case .failure(let err):
                    print(err)
                }
            }
        
    }
    
    
    private static func toJson<T: Decodable>(object: Any) -> T? {
        if let jsonData = try? JSONSerialization.data(withJSONObject: object) {
            let decoder = JSONDecoder()
            
            if let result = try? decoder.decode(T.self, from: jsonData) {
                return result
            } else {
                return nil
            }
        } else {
          return nil
        }
    }
    
    func logOut() {
        try! Auth.auth().signOut()
    }
    
    func delete(reason: String) {
        ref.child("users").child(myUserModel.uuid).removeValue()
        let key = ref.child("letters").childByAutoId().key!
        ref.child("letters").child(key).setValue(reason)
    }
    
    func removeIGInfo() {
        ref.child("users").child(myUserModel.uuid).child("igInfo").removeValue()
        myUserModel.igModel = nil
        igValidSubject.onNext(false)
    }
}

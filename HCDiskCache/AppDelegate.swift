//
//  AppDelegate.swift
//  HCDiskCache
//
//  Created by hehaichi on 2018/5/24.
//  Copyright © 2018年 hehaichi. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
    
        //MARK:- 测试是否存储是否正确
        let cache = HCDiskCacheOperator.init() //使用默认userIdf
        cache.hc_setString("hello wrold", forKey: "myKey1")
        cache.hc_setString("窗前明月光", forKey: "myKey1")
        cache.hc_setInt(345, forKey: "myKey1")
        cache.hc_setDouble(615.5, forKey: "myKey1")
        if let res = cache.hc_Double(forKey: "myKey1"){
            print("the cache value is \(res)")
        }
        
        //MARK:- 测试多表存储
        let cache2 = HCDiskCacheOperator.init(userIdentify: "MyuserIdentify2") //使用默认userIdf
        cache2.hc_setString("hello wrold hello wrold", forKey: "myKey1")
        cache2.hc_setString("窗前明月光，疑是地上霜，举头望明月，低头思故乡", forKey: "myKey1")
        cache2.hc_setInt(345345, forKey: "myKey1")
        cache2.hc_setDouble(615.5555, forKey: "myKey1")
       
        if let res = cache.hc_Double(forKey: "myKey1"){
            print("the cache value is \(res)")
        }
        if let res2 = cache2.hc_Double(forKey: "myKey1"){
            print("the cache2 value is \(res2)")
        }
        
        //MARK:- 测试增删改查速度
//        let timeStamp1 = Date().timeIntervalSince1970
//        for i in 0..<10000{
//            cache.hc_setString("窗前明月光，疑是地上霜，举头望明月，低头思故乡", forKey: String.init(i))
//        }
//        let timeStamp2 = Date().timeIntervalSince1970
        
//        for i in 0..<10000{
//            cache.hc_setString("窗前明月光，疑是地上霜，举头望明月，低头思故乡", forKey: String.init(i))
//        }
//        let timeStamp3 = Date().timeIntervalSince1970
////
//        for i in 0..<10000{
//            cache.hc_remove(forKey: String.init(i))
//        }
//        let timeStamp4 = Date().timeIntervalSince1970
        
//        print("新增10000个时间差:\(timeStamp2-timeStamp1)")
//        print("修改10000个时间差:\(timeStamp3-timeStamp2)")
//        print("移除10000个时间差:\(timeStamp4-timeStamp3)")
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}


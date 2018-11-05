//
//  Performance.swift
//  HCDiskCache
//
//  Created by hehaichi on 2018/11/5.
//  Copyright © 2018年 hehaichi. All rights reserved.
//

import UIKit

class Performance: NSObject {
    let cache = HCDiskCacheOperator.init()
    func intTest(){
        let begin = CACurrentMediaTime();
        for i in 0..<10000 {
            cache.setInt(i, forKey: "int-\(i)");
        }
        let end = CACurrentMediaTime();
        let time = end - begin
        let str = String.init(format: "HCDiskCache:  %.2f\n",  time)
        print(str);
    }
    
    func dicTest(){
        let begin = CACurrentMediaTime();
        for i in 0..<10000 {
            cache.setDictionary(["key":"\(i)"], forKey: "dic-\(i)");
        }
        let end = CACurrentMediaTime();
        let time = end - begin
        let str = String.init(format: "HCDiskCache:  %.2f\n",  time)
        print(str);
    }
}

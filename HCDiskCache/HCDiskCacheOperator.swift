//
//  HCDiskCacheOperator.swift
//  DXZtest
//
//  Created by hehaichi on 2018/5/22.
//  Copyright © 2018年 hehaichi. All rights reserved.
//

import UIKit
import SQLite
enum HCCacheDataType:Int {
    case HCCacheDataTypeString =        1
    case HCCacheDataTypeInt =           2
    case HCCacheDataTypeBool =          3
    case HCCacheDataTypeDouble =        4
    case HCCacheDataTypeArray =         5
    case HCCacheDataTypeDictionary =    6
}
protocol HCCacheDelegate {
    
    func setString(_ value:String,forKey key:String)
    func setBool(_ value:Bool,forKey key:String)
    func setInt(_ value:Int,forKey key:String)
    func setDouble(_ value:Double,forKey key:String)
    func setArray(_ value:NSArray,forKey key:String)
    func setDictionary(_ value:NSDictionary,forKey key:String)
    func set(_ value:Any,forkey key:String)
    
    func string(forKey key:String)->String?
    func bool(forKey key:String)->Bool?
    func int(forKey key:String)->Int?
    func double(forKey key:String)->Double?
    func array(forKey key:String)->NSArray?
    func dictionary(forKey key:String)->NSDictionary?
    func object(forkey key:String)->Any?
    
    func removeString(forKey key:String)->Bool
    func removeBool(forKey key:String)->Bool
    func removeInt(forKey key:String)->Bool
    func removeDouble(forKey key:String)->Bool
    func removeArray(forKey key:String)->Bool
    func removeDictionary(forKey key:String)->Bool
    func remove(forKey key:String)->Bool
 
}

class HCDiskCacheOperator: NSObject {
    private var _userIdentify = "default"
    init(userIdentify:String = "default") {
        _userIdentify = userIdentify
        super.init()
    }
    private let _lock = DispatchSemaphore.init(value: 1)
    
    //MARK: - public
    ///清空所有的数据，默认保留空表
    public func clear(remainTable:Bool = true){
        let table = self._getStringTabel()
        if let db = HCDiskCacheOperator._getDB(){
            if remainTable == false{
                do {
                    try db.run(table.drop(ifExists: true))
                    print("drop the table success")
                }catch{
                    print("drop the table fail \(error)")
                }
            }else{
                do {
                    try db.run(table.delete())
                    print("delete every row in the table success")
                }catch{
                    print("delete every row in the table fail \(error)")
                }
                
            }
        }
    }
    
    //MARK: - private
    ///获取数据库
    private static func _getDB()->Connection?{
        var db:Connection? = nil
        do {
            let path = NSSearchPathForDirectoriesInDomains(
                .documentDirectory, .userDomainMask, true
                ).first!
            db = try Connection("\(path)/db.sqlite3")
        }catch{
           print("connect db failed: \(error)")
        }
        return db
    }
    
    private func _getStringTabel()->Table{
        return Table(self._userIdentify+"_StringTable")
    }
    
    private func _getObject(forKey key:String,type:HCCacheDataType)->String?{
        _lock.wait()
        let res = __getObject(forKey: key, type: type);
        _lock.signal()
        return res;
    }
    
    private func __getObject(forKey key:String,type:HCCacheDataType)->String?{
        if let db = HCDiskCacheOperator._getDB(){
            let table = self._getStringTabel()
            let _key = Expression<String>("key")
            let _value = Expression<String>("value")
            let _type = Expression<Int>("type")
            
            var resultTable:Table? = nil
            resultTable = table.filter(_key == key)
            if let resTab = resultTable{
                do {
                    let resSequence = try db.prepare(resTab)
                    let resArray = Array.init(resSequence)
                    if resArray.count > 0{
                        print("query the result: \(key):\(String(describing: resArray.first?[_value]))")
                        if resArray.first?[_type] == type.rawValue{
                            return resArray.first?[_value]
                        }     
                    }else{
                        print("do not query the result for the key:\(key)")
                    }
                }catch{
                    print("query error:\(error)")
                }
            }
        }
        return nil
    }
    
    private func _setObject(_ value:String,forKey key:String,type:HCCacheDataType){
        _lock.wait()
        __setObject(value, forKey: key, type: type);
        _lock.signal()
    }
    
    private func __setObject(_ value:String,forKey key:String,type:HCCacheDataType){
        if let db = HCDiskCacheOperator._getDB(){
            let table = self._getStringTabel()
            var needInsert = false
            let _id = Expression<Int64>("id")
            let _key = Expression<String>("key")
            let _value = Expression<String>("value")
            let _type = Expression<Int>("type")
            
            do {//如果表不存在，就先创建表
                
                try db.run(table.create(ifNotExists: true) { t in
                    t.column(_id, primaryKey: true)
                    t.column(_key,unique: true)
                    t.column(_value)
                    t.column(_type)
                })
            }catch{
                print("create failed: \(error)")
            }
            do {
                
                //然后表中已经存在_key为key(key是实际字符串)的值，则更新
                let alice = table.filter(_key == key)
                if try db.run(alice.update(_value <- value,_type <- type.rawValue)) > 0 {
                    print("updated \(key) to \(value)")//更新
                } else {//发现无法更新，则需要插入
                    needInsert = true
                    print("\(key):\(value) need to insert")
                    
                }
            } catch {
                print("update failed: \(error)")
            }
            if needInsert {//需要插入
                do {
                    try db.run(table.insert(_key <- key,_value <- value,_type <- type.rawValue))
                    print("\(key):\(value) insert to table ")
                } catch let Result.error(message, code, statement) where code == SQLITE_CONSTRAINT {
                    print("constraint failed: \(message), in \(String(describing: statement))")
                } catch let error {
                    print("insertion failed: \(error)")
                }
            }
        }
        
    }
    
    private func _removeObject(forKey key:String)->Bool{
        _lock.wait()
        let res = __removeObject(forKey: key);
        _lock.signal()
        return res;
    }
    
    private func __removeObject(forKey key:String)->Bool{
        var success = false
        if let db = HCDiskCacheOperator._getDB(){
            let table = self._getStringTabel()
            let _key = Expression<String>("key")
            let alice = table.filter(_key == key)
            do {
                if try db.run(alice.delete()) > 0 {
                    print("\(key) delete success")
                    success = true
                } else {
                    print("\(key) do not found, delete fail")
                }
            } catch {
                print("delete failed: \(error)")
            }
        }
        return success
    }
    
    
}

extension HCDiskCacheOperator: HCCacheDelegate {

    func setString(_ value: String, forKey key: String) {
        self._setObject(value, forKey: key, type: .HCCacheDataTypeString)
    }
    
    func setBool(_ value:Bool,forKey key:String){
        let v1 = String(value)
        self._setObject(v1, forKey: key, type: .HCCacheDataTypeBool)
    }
    
    func setInt(_ value:Int,forKey key:String){
        let v1 = String(value)
        self._setObject(v1, forKey: key, type: .HCCacheDataTypeInt)
        
    }
    
    func setDouble(_ value:Double,forKey key:String){
        let v1 = String(value)
        self._setObject(v1, forKey: key, type: .HCCacheDataTypeDouble)
    }
    
    func setArray(_ value: NSArray, forKey key: String) {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: value, options: [])
            if let str = NSString.init(data: jsonData, encoding: String.Encoding.utf8.rawValue) as String?{
                self._setObject(str, forKey: key, type: .HCCacheDataTypeArray)
            }
            
        }catch{
            
        }
    }
    
    func setDictionary(_ value: NSDictionary, forKey key: String) {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: value, options: [])
            if let str = NSString.init(data: jsonData, encoding: String.Encoding.utf8.rawValue) as String?{
                self._setObject(str, forKey: key, type: .HCCacheDataTypeDictionary)
            }
            
        }catch{
            
        }
    }
    
    func set(_ value:Any,forkey key:String){
        if value is String{
            if let v1 = value as? String{
                self.setString(v1, forKey: key)
            }
        }else if value is Int{
            if let v1 = value as? Int{
                self.setInt(v1, forKey: key)
            }
            
        }else if value is Bool{
            if let v1 = value as? Bool{
                self.setBool(v1, forKey: key)
            }
        }else if value is Double{
            if let v1 = value as? Double{
                self.setDouble(v1, forKey: key)
            }
        }else if value is NSDictionary{
            if let v1 = value as? NSDictionary{
                self.setDictionary(v1, forKey: key)
            }
        }else if value is NSArray{
            if let v1 = value as? NSArray{
                self.setArray(v1, forKey: key)
            }
        }
    }

    func string(forKey key:String)->String?{
        return self._getObject(forKey: key, type: .HCCacheDataTypeString)
    }
    
    
    func bool(forKey key:String)->Bool?{
        if let str = self._getObject(forKey: key, type: .HCCacheDataTypeBool){
            return Bool(str)
        }
        return nil
    }
    
    func int(forKey key:String)->Int?{
        if let str =  self._getObject(forKey: key, type: .HCCacheDataTypeInt){
            return Int(str)
        }
        return nil
    }
    
    func double(forKey key:String)->Double?{
        if let str =  self._getObject(forKey: key, type: .HCCacheDataTypeDouble){
            return Double(str)
        }
        return nil
    }
    
    func array(forKey key: String) -> NSArray? {
        if let res =  self._getObject(forKey: key, type: .HCCacheDataTypeArray){
            if let data = res.data(using: String.Encoding(rawValue: String.Encoding.utf8.rawValue)){
                do {
                    let jsonData = try JSONSerialization.jsonObject(with: data, options: [])
                    if let jsonDic = jsonData as? NSArray{
                        return jsonDic
                    }
                    
                }catch{
                    
                }
            }
        }
        return nil
    }
    
    func dictionary(forKey key: String) -> NSDictionary? {
        if let res =  self._getObject(forKey: key, type: .HCCacheDataTypeDictionary){
            if let data = res.data(using: String.Encoding(rawValue: String.Encoding.utf8.rawValue)){
                do {
                    let jsonData = try JSONSerialization.jsonObject(with: data, options: [])
                    if let jsonDic = jsonData as? NSDictionary{
                        return jsonDic
                    }
                    
                }catch{
                    
                }
            }
        }
        return nil
    }
    
    func object(forkey key:String)->Any?{
        return self.string(forKey: key)
    }
    
    func removeString(forKey key:String)->Bool{
        return self._removeObject(forKey:key)
    }
    
    func removeBool(forKey key:String)->Bool{
        return self._removeObject(forKey:key)
    }
    
    func removeInt(forKey key:String)->Bool{
        return self._removeObject(forKey:key)
    }
    
    func removeDouble(forKey key:String)-> Bool{
        return self._removeObject(forKey:key)
    }
    
    func removeArray(forKey key: String) -> Bool {
        return self._removeObject(forKey:key)
    }
    
    func removeDictionary(forKey key: String) -> Bool {
        return self._removeObject(forKey:key)
    }
    
    func remove(forKey key:String)->Bool{
        return self._removeObject(forKey:key)
    }
}

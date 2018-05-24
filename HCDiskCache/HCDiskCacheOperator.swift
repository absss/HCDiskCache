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
    
    func hc_setString(_ value:String,forKey key:String)
    func hc_setBool(_ value:Bool,forKey key:String)
    func hc_setInt(_ value:Int,forKey key:String)
    func hc_setDouble(_ value:Double,forKey key:String)
    func hc_setArray(_ value:NSArray,forKey key:String)
    func hc_setDictionary(_ value:NSDictionary,forKey key:String)
    func hc_set(_ value:Any,forkey key:String)
    
    func hc_String(forKey key:String)->String?
    func hc_Bool(forKey key:String)->Bool?
    func hc_Int(forKey key:String)->Int?
    func hc_Double(forKey key:String)->Double?
    func hc_Array(forKey key:String)->NSArray?
    func hc_Dictionary(forKey key:String)->NSDictionary?
    func hc_object(forkey key:String)->Any?
    
    func hc_removeString(forKey key:String)->Bool
    func hc_removeBool(forKey key:String)->Bool
    func hc_removeInt(forKey key:String)->Bool
    func hc_removeDouble(forKey key:String)->Bool
    func hc_removeArray(forKey key:String)->Bool
    func hc_removeDictionary(forKey key:String)->Bool
    func hc_remove(forKey key:String)->Bool
 
}

class HCDiskCacheOperator: NSObject {
    private var _userIdentify = "default"
    init(userIdentify:String = "default") {
        _userIdentify = userIdentify
        super.init()
       
    }
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
                        print("do not query the result...")
                    }
                }catch{
                    print("query error:\(error)")
                }
            }
        }
        return nil
    }
    private func _setObject(_ value:String,forKey key:String,type:HCCacheDataType){
        
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
        var success = false
        if let db = HCDiskCacheOperator._getDB(){
            let table = self._getStringTabel()
            let _key = Expression<String>("key")
            let alice = table.filter(_key == key)
            do {
                if try db.run(alice.delete()) > 0 {
                    print("\(key) deleted success")
                    success = true
                } else {
                    print("\(key) do not found")
                }
            } catch {
                print("delete failed: \(error)")
            }
        }
        return success
    }
    
    
}

extension HCDiskCacheOperator: HCCacheDelegate {

    func hc_setString(_ value: String, forKey key: String) {
        self._setObject(value, forKey: key, type: .HCCacheDataTypeString)
    }
    
    func hc_set(_ value:Any,forkey key:String){
        if value is String{
            if let v1 = value as? String{
                self.hc_setString(v1, forKey: key)
            }
        }else if value is Int{
            if let v1 = value as? Int{
                self.hc_setInt(v1, forKey: key)
            }
            
        }else if value is Bool{
            if let v1 = value as? Bool{
                self.hc_setBool(v1, forKey: key)
            }
        }else if value is Double{
            if let v1 = value as? Double{
                self.hc_setDouble(v1, forKey: key)
            }
        }else if value is NSDictionary{
            if let v1 = value as? NSDictionary{
                self.hc_setDictionary(v1, forKey: key)
            }
        }else if value is NSArray{
            if let v1 = value as? NSArray{
                self.hc_setArray(v1, forKey: key)
            }
        }
    }
    
    
    func hc_setBool(_ value:Bool,forKey key:String){
        let v1 = String(value)
        self._setObject(v1, forKey: key, type: .HCCacheDataTypeBool)
    }
    
    func hc_setInt(_ value:Int,forKey key:String){
        let v1 = String(value)
        self._setObject(v1, forKey: key, type: .HCCacheDataTypeInt)
        
    }
    
    func hc_setDouble(_ value:Double,forKey key:String){
        let v1 = String(value)
        self._setObject(v1, forKey: key, type: .HCCacheDataTypeDouble)
    }
    
    func hc_setArray(_ value: NSArray, forKey key: String) {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: value, options: [])
            if let str = NSString.init(data: jsonData, encoding: String.Encoding.utf8.rawValue) as String?{
                self._setObject(str, forKey: key, type: .HCCacheDataTypeArray)
            }
            
        }catch{
            
        }
    }
    
    func hc_setDictionary(_ value: NSDictionary, forKey key: String) {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: value, options: [])
            if let str = NSString.init(data: jsonData, encoding: String.Encoding.utf8.rawValue) as String?{
                self._setObject(str, forKey: key, type: .HCCacheDataTypeDictionary)
            }
            
        }catch{
            
        }
    }
    
    func hc_String(forKey key:String)->String?{
        return self._getObject(forKey: key, type: .HCCacheDataTypeString)
    }
    
    func hc_object(forkey key:String)->Any?{
         return self.hc_String(forKey: key)   
    }
    
    func hc_Bool(forKey key:String)->Bool?{
        if let str = self._getObject(forKey: key, type: .HCCacheDataTypeBool){
            return Bool(str)
        }
        return nil
    }
    
    func hc_Int(forKey key:String)->Int?{
        if let str =  self._getObject(forKey: key, type: .HCCacheDataTypeInt){
            return Int(str)
        }
        return nil
    }
    
    func hc_Double(forKey key:String)->Double?{
        if let str =  self._getObject(forKey: key, type: .HCCacheDataTypeDouble){
            return Double(str)
        }
        return nil
    }
    
    func hc_Array(forKey key: String) -> NSArray? {
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
    
    func hc_Dictionary(forKey key: String) -> NSDictionary? {
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
    func hc_removeString(forKey key:String)->Bool{
        return self._removeObject(forKey:key)
    }
    
    func hc_removeBool(forKey key:String)->Bool{
        return self._removeObject(forKey:key)
    }
    
    func hc_removeInt(forKey key:String)->Bool{
        return self._removeObject(forKey:key)
    }
    
    func hc_removeDouble(forKey key:String)-> Bool{
        return self._removeObject(forKey:key)
    }
    
    func hc_removeArray(forKey key: String) -> Bool {
        return self._removeObject(forKey:key)
    }
    
    func hc_removeDictionary(forKey key: String) -> Bool {
        return self._removeObject(forKey:key)
    }
    
    func hc_remove(forKey key:String)->Bool{
        return self._removeObject(forKey:key)
    }

}

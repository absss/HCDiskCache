# HCDiskCache
使用SQLite.swift写的磁盘缓存demo

[SQLite.swift文档链接](https://github.com/stephencelis/SQLite.swift/blob/master/Documentation/Index.md#installation)
## 说明
我使用的是Xcode9.2，对应的SQLite.swift版本是0.11.4，我写这个md的时候，最新的SQLite.swift的版本0.11.5，对应Xcode9.3，具体可以去github上看他的官方资料
## 使用方式
```
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
```
iPhone6模拟器 测试数据
| 插入10000条数据的时间（秒）| 更新10000条数据的时间（秒） | 删除10000条数据的时间（秒） | 
| - | - | - |
| 29.9169731140137 | 22.6273632049561| 18.5146188735962	 | 
| 29.265772819519 | 23.053731918335 | 18.2116186903566  | 
| 29.7147810459137 | 23.0141839981079 | 19.0116116903796  |
| 29.818051815033 | 24.660277128219 | 18.8116116903796  |
| 29.512325181503 | 23.3970768451691 | 18.4017116103756  |


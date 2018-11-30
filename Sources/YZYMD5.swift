//
//  YZYMD5.swift
//
//  Created by Yang Zhi Yong on 2018/10/11.
//  Copyright © 2018 Yang Zhi Yong. All rights reserved.
//

import Foundation

public class YZYMD5: NSObject {
    
    var a: Int32
    var b: Int32
    var c: Int32
    var d: Int32
    
    var buffer: [Int32]
    let BufferSize = 64
    var buffer_length: Int
    var total_length: Int64
    
    var temp_uint8_1: UInt8 = 0
    var temp_uint8_2: UInt8 = 0
    var temp_uint8_3: UInt8 = 0
    var temp_uint8_4: UInt8 = 0
    
    var temp_int32: Int32 = 0
    
    override public init() {
        self.a = 1732584193
        self.b = -271733879
        self.c = -1732584194
        self.d = 271733878
        
        self.buffer = [Int32](repeating: 0, count: 16)
        self.buffer_length = 0
        self.total_length = 0
        
        super.init()
    }
    
    public func digestFromFile(_ atPath: String) -> String {
        
        var result = ""
        
        if self.update_from_file(atPath) {
            result = digest()
        }
        
        return result
    }
    
    public func digestHexFromFile(_ atPath: String) -> String {
        
        var result = ""
        
        if self.update_from_file(atPath) {
            result = digestHex()
        }
        
        return result
    }
    
    public func update(_ input: String) {
        self.md5_update(self.str_to_uint8_array(input))
    }
    
    public func digest() -> String {
        self.md5_done()
        return uint8_array_to_string(int32_array_to_uint8_array([self.a, self.b, self.c, self.d]))
    }
    
    public func digestHex() -> String {
        self.md5_done()
        return uint8_array_to_hex_string(int32_array_to_uint8_array([self.a, self.b, self.c, self.d]))
    }
    
    private func update_from_file(_ filePath: String) -> Bool {
        var result = false
        
        let inputStream = InputStream(fileAtPath: filePath)
        
        if inputStream != nil {
            inputStream!.open()
            
            let bufferSize = 1024
            let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
            
            while inputStream!.hasBytesAvailable {
                let readCount = inputStream!.read(buffer, maxLength: bufferSize)
                
                if readCount > 0 {
                    var block: [CUnsignedChar] = [CUnsignedChar](repeating: 0, count: readCount)
                    for i in 0..<readCount {
                        block[i] = buffer[i]
                    }
                    
                    self.md5_update(block)
                }
            }
            
            buffer.deallocate()
            
            inputStream!.close()
            
            result = true
        }else{
            result = false
        }
        
        return result
    }
    
    private func md5_update(_ input: [CUnsignedChar]) {
        
        var len = input.count
        
        // if buffer is full, clear
        if self.buffer_length >= self.BufferSize {
            self.md5_compress()
            self.clear_buffer()
            self.total_length += ( Int64(self.BufferSize) * 8 )
        }
        
        var processedCount = 0
        
        while len > 0 {
            let n = min(len, (self.BufferSize - self.buffer_length))
            
            for i in 0..<n {
                self.set_uint8_to_buffer(self.buffer_length + i, input[i + processedCount])
            }
            
            self.buffer_length += n
            len -= n
            processedCount += n
            
            if self.buffer_length >= self.BufferSize {
                self.md5_compress()
                self.clear_buffer()
                self.total_length += ( Int64(self.BufferSize) * 8 )
            }
        }
    }
    
    private func md5_done() {
        if self.buffer_length == 0{
            for i in 0..<16 {
                self.buffer[i] = 0
            }
            self.set_uint8_to_buffer(0, 128)
            self.set_total_length_to_buffer()
            
            self.md5_compress()
            self.clear_buffer()
        }
        else if self.buffer_length == 56 {
            
            
            self.total_length += ( Int64(56) * 8 )
            self.set_total_length_to_buffer()
            
            self.md5_compress()
            self.clear_buffer()
            
        }
        else if self.buffer_length < 56 {
            for i in self.buffer_length..<self.BufferSize {
                if i == self.buffer_length {
                    self.set_uint8_to_buffer(i, 128)
                }else{
                    self.set_uint8_to_buffer(i, 0)
                }
            }
            
            self.total_length += ( Int64(self.buffer_length) * 8 )
            self.set_total_length_to_buffer()
            
            self.md5_compress()
            self.clear_buffer()
            
        }
        else {
            self.total_length += ( Int64(self.buffer_length) * 8 )
            
            self.set_uint8_to_buffer(self.buffer_length, 128)
            self.md5_compress()
            self.clear_buffer()
            
            
            self.set_total_length_to_buffer()
            
            self.md5_compress()
            self.clear_buffer()
        }
    }
    
    private func clear_buffer() {
        self.buffer_length = 0
        for i in 0..<16 {
            self.buffer[i] = 0
        }
    }
    
    private func set_uint8_to_buffer(_ atPosition: Int, _ value: CUnsignedChar) {
        let index = (atPosition / 4, atPosition % 4)
        
        let buffer_item: Int32 = self.buffer[index.0];
        
        let new_buffer_item = self.set_uint8_to_int32(buffer_item, index.1, value)
        
        self.buffer[index.0] = new_buffer_item
    }
    
    private func get_uint8_from_int32(_ source: Int32, _ position: Int) -> UInt8 {
        var result: UInt8 = UInt8.max
        var tempInt32 = source
        
        if position < 4 && position >= 0 {
            tempInt32 = tempInt32 << ( (3 - position) * 8 )
            tempInt32 = tempInt32 >> 24
            tempInt32 = tempInt32 & Int32(255)
            result = UInt8(tempInt32)
        }
        
        //        print("get_uint8_from_int32: \(source)[\(position)]=\(result)")
        
        return result
    }
    
    private func concat_4_uint8_to_int32(_ uint8_1: UInt8,
                                         _ uint8_2: UInt8,
                                         _ uint8_3: UInt8,
                                         _ uint8_4: UInt8) -> Int32 {
        self.temp_int32 = 0
        
        self.temp_int32 = self.temp_int32 | Int32(uint8_4) << 24
        self.temp_int32 = self.temp_int32 | Int32(uint8_3) << 16
        self.temp_int32 = self.temp_int32 | Int32(uint8_2) << 8
        self.temp_int32 = self.temp_int32 | Int32(uint8_1)
        
        return self.temp_int32
    }
    
    private func set_uint8_to_int32(_ source: Int32, _ position: Int, _ value: UInt8) -> Int32 {
        
        switch position {
        case 0:
            self.temp_uint8_1 = value
            self.temp_uint8_2 = self.get_uint8_from_int32(source, 1)
            self.temp_uint8_3 = self.get_uint8_from_int32(source, 2)
            self.temp_uint8_4 = self.get_uint8_from_int32(source, 3)
            
        case 1:
            self.temp_uint8_1 = self.get_uint8_from_int32(source, 0)
            self.temp_uint8_2 = value
            self.temp_uint8_3 = self.get_uint8_from_int32(source, 2)
            self.temp_uint8_4 = self.get_uint8_from_int32(source, 3)
            
        case 2:
            self.temp_uint8_1 = self.get_uint8_from_int32(source, 0)
            self.temp_uint8_2 = self.get_uint8_from_int32(source, 1)
            self.temp_uint8_3 = value
            self.temp_uint8_4 = self.get_uint8_from_int32(source, 3)
            
            
        case 3:
            self.temp_uint8_1 = self.get_uint8_from_int32(source, 0)
            self.temp_uint8_2 = self.get_uint8_from_int32(source, 1)
            self.temp_uint8_3 = self.get_uint8_from_int32(source, 2)
            self.temp_uint8_4 = value
            
        default:
            self.temp_uint8_1 = 0
            self.temp_uint8_2 = 0
            self.temp_uint8_3 = 0
            self.temp_uint8_4 = 0
        }
        
        return self.concat_4_uint8_to_int32(self.temp_uint8_1,
                                            self.temp_uint8_2,
                                            self.temp_uint8_3,
                                            self.temp_uint8_4)
    }
    
    private func md5_compress() {
        
        var a: Int32 = self.a
        var b: Int32 = self.b
        var c: Int32 = self.c
        var d: Int32 = self.d
        
        a = ff(a, b, c, d, self.buffer[0] , 7 , -680876936)
        d = ff(d, a, b, c, self.buffer[1] , 12, -389564586)
        c = ff(c, d, a, b, self.buffer[2] , 17,  606105819)
        b = ff(b, c, d, a, self.buffer[3] , 22, -1044525330)
        a = ff(a, b, c, d, self.buffer[4] , 7 , -176418897)
        d = ff(d, a, b, c, self.buffer[5] , 12,  1200080426)
        c = ff(c, d, a, b, self.buffer[6] , 17, -1473231341)
        b = ff(b, c, d, a, self.buffer[7] , 22, -45705983)
        a = ff(a, b, c, d, self.buffer[8] , 7 ,  1770035416)
        d = ff(d, a, b, c, self.buffer[9] , 12, -1958414417)
        c = ff(c, d, a, b, self.buffer[10], 17, -42063)
        b = ff(b, c, d, a, self.buffer[11], 22, -1990404162)
        a = ff(a, b, c, d, self.buffer[12], 7 ,  1804603682)
        d = ff(d, a, b, c, self.buffer[13], 12, -40341101)
        c = ff(c, d, a, b, self.buffer[14], 17, -1502002290)
        b = ff(b, c, d, a, self.buffer[15], 22,  1236535329)
        
        a = gg(a, b, c, d, self.buffer[1] , 5 , -165796510)
        d = gg(d, a, b, c, self.buffer[6] , 9 , -1069501632)
        c = gg(c, d, a, b, self.buffer[11], 14,  643717713)
        b = gg(b, c, d, a, self.buffer[0] , 20, -373897302)
        a = gg(a, b, c, d, self.buffer[5] , 5 , -701558691)
        d = gg(d, a, b, c, self.buffer[10], 9 ,  38016083)
        c = gg(c, d, a, b, self.buffer[15], 14, -660478335)
        b = gg(b, c, d, a, self.buffer[4] , 20, -405537848)
        a = gg(a, b, c, d, self.buffer[9] , 5 ,  568446438)
        d = gg(d, a, b, c, self.buffer[14], 9 , -1019803690)
        c = gg(c, d, a, b, self.buffer[3] , 14, -187363961)
        b = gg(b, c, d, a, self.buffer[8] , 20,  1163531501)
        a = gg(a, b, c, d, self.buffer[13], 5 , -1444681467)
        d = gg(d, a, b, c, self.buffer[2] , 9 , -51403784)
        c = gg(c, d, a, b, self.buffer[7] , 14,  1735328473)
        b = gg(b, c, d, a, self.buffer[12], 20, -1926607734)
        
        a = hh(a, b, c, d, self.buffer[5] , 4 , -378558)
        d = hh(d, a, b, c, self.buffer[8] , 11, -2022574463)
        c = hh(c, d, a, b, self.buffer[11], 16,  1839030562)
        b = hh(b, c, d, a, self.buffer[14], 23, -35309556)
        a = hh(a, b, c, d, self.buffer[1] , 4 , -1530992060)
        d = hh(d, a, b, c, self.buffer[4] , 11,  1272893353)
        c = hh(c, d, a, b, self.buffer[7] , 16, -155497632)
        b = hh(b, c, d, a, self.buffer[10], 23, -1094730640)
        a = hh(a, b, c, d, self.buffer[13], 4 ,  681279174)
        d = hh(d, a, b, c, self.buffer[0] , 11, -358537222)
        c = hh(c, d, a, b, self.buffer[3] , 16, -722521979)
        b = hh(b, c, d, a, self.buffer[6] , 23,  76029189)
        a = hh(a, b, c, d, self.buffer[9] , 4 , -640364487)
        d = hh(d, a, b, c, self.buffer[12], 11, -421815835)
        c = hh(c, d, a, b, self.buffer[15], 16,  530742520)
        b = hh(b, c, d, a, self.buffer[2] , 23, -995338651)
        
        a = ii(a, b, c, d, self.buffer[0] , 6 , -198630844)
        d = ii(d, a, b, c, self.buffer[7] , 10,  1126891415)
        c = ii(c, d, a, b, self.buffer[14], 15, -1416354905)
        b = ii(b, c, d, a, self.buffer[5] , 21, -57434055)
        a = ii(a, b, c, d, self.buffer[12], 6 ,  1700485571)
        d = ii(d, a, b, c, self.buffer[3] , 10, -1894986606)
        c = ii(c, d, a, b, self.buffer[10], 15, -1051523)
        b = ii(b, c, d, a, self.buffer[1] , 21, -2054922799)
        a = ii(a, b, c, d, self.buffer[8] , 6 ,  1873313359)
        d = ii(d, a, b, c, self.buffer[15], 10, -30611744)
        c = ii(c, d, a, b, self.buffer[6] , 15, -1560198380)
        b = ii(b, c, d, a, self.buffer[13], 21,  1309151649)
        a = ii(a, b, c, d, self.buffer[4] , 6 , -145523070)
        d = ii(d, a, b, c, self.buffer[11], 10, -1120210379)
        c = ii(c, d, a, b, self.buffer[2] , 15,  718787259)
        b = ii(b, c, d, a, self.buffer[9] , 21, -343485551)
        
        self.a = safe_add(a, self.a)
        self.b = safe_add(b, self.b)
        self.c = safe_add(c, self.c)
        self.d = safe_add(d, self.d)
    }
    
    private func zeroFillRightShift(_ num: Int32, _ count: Int32) -> Int32 {
        let value = UInt32(bitPattern: num) >> UInt32(bitPattern: count)
        return Int32(bitPattern: value)
    }
    
    private func bit_rol(_ num: Int32, _ cnt: Int32) -> Int32 {
        // num >>>
        return (num << cnt) | zeroFillRightShift(num, (32 - cnt))
    }
    
    private func md5_cmn(_ q: Int32, _ a: Int32, _ b: Int32, _ x: Int32, _ s: Int32, _ t: Int32) -> Int32 {
        return safe_add(bit_rol(safe_add(safe_add(a, q), safe_add(x, t)), s), b)
    }
    
    private func ff(_ a: Int32, _ b: Int32, _ c: Int32, _ d: Int32, _ x: Int32, _ s: Int32, _ t: Int32) -> Int32 {
        return md5_cmn((b & c) | ((~b) & d), a, b, x, s, t)
    }
    
    private func gg(_ a: Int32, _ b: Int32, _ c: Int32, _ d: Int32, _ x: Int32, _ s: Int32, _ t: Int32) -> Int32 {
        return md5_cmn((b & d) | (c & (~d)), a, b, x, s, t)
    }
    
    private func hh(_ a: Int32, _ b: Int32, _ c: Int32, _ d: Int32, _ x: Int32, _ s: Int32, _ t: Int32) -> Int32 {
        return md5_cmn(b ^ c ^ d, a, b, x, s, t)
    }
    
    private func ii(_ a: Int32, _ b: Int32, _ c: Int32, _ d: Int32, _ x: Int32, _ s: Int32, _ t: Int32) -> Int32 {
        return md5_cmn(c ^ (b | (~d)), a, b, x, s, t)
    }
    
    private func str_to_uint8_array(_ input: String) -> [CUnsignedChar] {
        return Array(input.utf8)
    }
    
    private func int32_array_to_uint8_array(_ input: [Int32]) -> [CUnsignedChar] {
        var output: [CUnsignedChar] = []
        
        for i in 0..<input.count {
            let buffer_item: Int32 = input[i]
            for j in 0..<4 {
                let uint8_item = self.get_uint8_from_int32(buffer_item, j)
                output.append(uint8_item)
            }
        }
        
        return output
    }
    
    private func uint8_array_to_string(_ input: [CUnsignedChar]) -> String {
        var output: String = ""
        
        input.forEach {
            output.append(String(UnicodeScalar($0)))
        }
        
        return output
    }
    
    private func uint8_array_to_hex_string(_ input: [CUnsignedChar]) -> String {
        let hexTab: [Character] = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "A", "B", "C", "D", "E", "F"]
        var output: [Character] = []
        
        for i in 0..<input.count {
            let x = input[i]
            let value1 = hexTab[Int((x >> 4) & 0x0F)]
            let value2 = hexTab[Int(Int32(x) & 0x0F)]
            
            output.append(value1)
            output.append(value2)
        }
        
        return String(output)
    }
    
    private func safe_add(_ x: Int32, _ y: Int32) -> Int32 {
        return x &+ y
    }
    
    private func set_total_length_to_buffer() {
        self.buffer[14] = Int32( (self.total_length << 32) >> 32 )
//        self.buffer[15] = Int32( (self.total_length >> 32) << 32 )
        self.buffer[15] = Int32( self.total_length >> 32 )
        
    }
}

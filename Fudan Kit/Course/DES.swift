import Foundation

/// AI Generated
enum DES {
    private static let sBoxes: [[[Int]]] = [
        [
            [14, 4, 13, 1, 2, 15, 11, 8, 3, 10, 6, 12, 5, 9, 0, 7],
            [0, 15, 7, 4, 14, 2, 13, 1, 10, 6, 12, 11, 9, 5, 3, 8],
            [4, 1, 14, 8, 13, 6, 2, 11, 15, 12, 9, 7, 3, 10, 5, 0],
            [15, 12, 8, 2, 4, 9, 1, 7, 5, 11, 3, 14, 10, 0, 6, 13],
        ],
        [
            [15, 1, 8, 14, 6, 11, 3, 4, 9, 7, 2, 13, 12, 0, 5, 10],
            [3, 13, 4, 7, 15, 2, 8, 14, 12, 0, 1, 10, 6, 9, 11, 5],
            [0, 14, 7, 11, 10, 4, 13, 1, 5, 8, 12, 6, 9, 3, 2, 15],
            [13, 8, 10, 1, 3, 15, 4, 2, 11, 6, 7, 12, 0, 5, 14, 9],
        ],
        [
            [10, 0, 9, 14, 6, 3, 15, 5, 1, 13, 12, 7, 11, 4, 2, 8],
            [13, 7, 0, 9, 3, 4, 6, 10, 2, 8, 5, 14, 12, 11, 15, 1],
            [13, 6, 4, 9, 8, 15, 3, 0, 11, 1, 2, 12, 5, 10, 14, 7],
            [1, 10, 13, 0, 6, 9, 8, 7, 4, 15, 14, 3, 11, 5, 2, 12],
        ],
        [
            [7, 13, 14, 3, 0, 6, 9, 10, 1, 2, 8, 5, 11, 12, 4, 15],
            [13, 8, 11, 5, 6, 15, 0, 3, 4, 7, 2, 12, 1, 10, 14, 9],
            [10, 6, 9, 0, 12, 11, 7, 13, 15, 1, 3, 14, 5, 2, 8, 4],
            [3, 15, 0, 6, 10, 1, 13, 8, 9, 4, 5, 11, 12, 7, 2, 14],
        ],
        [
            [2, 12, 4, 1, 7, 10, 11, 6, 8, 5, 3, 15, 13, 0, 14, 9],
            [14, 11, 2, 12, 4, 7, 13, 1, 5, 0, 15, 10, 3, 9, 8, 6],
            [4, 2, 1, 11, 10, 13, 7, 8, 15, 9, 12, 5, 6, 3, 0, 14],
            [11, 8, 12, 7, 1, 14, 2, 13, 6, 15, 0, 9, 10, 4, 5, 3],
        ],
        [
            [12, 1, 10, 15, 9, 2, 6, 8, 0, 13, 3, 4, 14, 7, 5, 11],
            [10, 15, 4, 2, 7, 12, 9, 5, 6, 1, 13, 14, 0, 11, 3, 8],
            [9, 14, 15, 5, 2, 8, 12, 3, 7, 0, 4, 10, 1, 13, 11, 6],
            [4, 3, 2, 12, 9, 5, 15, 10, 11, 14, 1, 7, 6, 0, 8, 13],
        ],
        [
            [4, 11, 2, 14, 15, 0, 8, 13, 3, 12, 9, 7, 5, 10, 6, 1],
            [13, 0, 11, 7, 4, 9, 1, 10, 14, 3, 5, 12, 2, 15, 8, 6],
            [1, 4, 11, 13, 12, 3, 7, 14, 10, 15, 6, 8, 0, 5, 9, 2],
            [6, 11, 13, 8, 1, 4, 10, 7, 9, 5, 0, 15, 14, 2, 3, 12],
        ],
        [
            [13, 2, 8, 4, 6, 15, 11, 1, 10, 9, 3, 14, 5, 0, 12, 7],
            [1, 15, 13, 8, 10, 3, 7, 4, 12, 5, 6, 11, 0, 14, 9, 2],
            [7, 11, 4, 1, 9, 12, 14, 2, 0, 6, 10, 13, 15, 3, 5, 8],
            [2, 1, 14, 7, 4, 10, 8, 13, 15, 12, 9, 0, 3, 5, 6, 11],
        ],
    ]

    private static let pPermutation = [
        15, 6, 19, 20, 28, 11, 27, 16,
        0, 14, 22, 25, 4, 17, 30, 9,
        1, 7, 23, 13, 31, 26, 2, 8,
        18, 12, 29, 5, 21, 10, 3, 24,
    ]

    private static let pc2 = [
        13, 16, 10, 23, 0, 4, 2, 27,
        14, 5, 20, 9, 22, 18, 11, 3,
        25, 7, 15, 6, 26, 19, 12, 1,
        40, 51, 30, 36, 46, 54, 29, 39,
        50, 44, 32, 47, 43, 48, 38, 55,
        33, 52, 45, 41, 49, 35, 28, 31,
    ]

    private static let keyShifts = [
        1, 1, 2, 2, 2, 2, 2, 2,
        1, 2, 2, 2, 2, 2, 2, 1,
    ]

    static func encrypt(_ plaintext: String) -> String {
        if plaintext.isEmpty { return "" }
        return tripleDESEncrypt(plaintext, key1: "1", key2: "2", key3: "3")
    }

    private static func tripleDESEncrypt(_ plaintext: String, key1: String, key2: String, key3: String) -> String {
        let keys1 = splitKey(key1)
        let keys2 = splitKey(key2)
        let keys3 = splitKey(key3)

        var result = ""
        let codeUnits = Array(plaintext.utf16)
        let fullBlocks = codeUnits.count / 4
        let remainder = codeUnits.count % 4

        for i in 0..<fullBlocks {
            let blockUnits = Array(codeUnits[(i * 4)..<(i * 4 + 4)])
            var block = textToBlock(blockUnits)
            block = applyKeys(block, keyBlocks: keys1)
            block = applyKeys(block, keyBlocks: keys2)
            block = applyKeys(block, keyBlocks: keys3)
            result += blockToHex(block)
        }

        if remainder > 0 {
            let blockUnits = Array(codeUnits[(fullBlocks * 4)..<codeUnits.count])
            var block = textToBlock(blockUnits)
            block = applyKeys(block, keyBlocks: keys1)
            block = applyKeys(block, keyBlocks: keys2)
            block = applyKeys(block, keyBlocks: keys3)
            result += blockToHex(block)
        }

        return result
    }

    private static func applyKeys(_ block: [Int], keyBlocks: [[Int]]) -> [Int] {
        var result = block
        for keyBlock in keyBlocks {
            result = desEncryptBlock(result, key: keyBlock)
        }
        return result
    }

    private static func splitKey(_ key: String) -> [[Int]] {
        let units = Array(key.utf16)
        var result: [[Int]] = []
        let fullBlocks = units.count / 4
        let remainder = units.count % 4

        for i in 0..<fullBlocks {
            result.append(textToBlock(Array(units[(i * 4)..<(i * 4 + 4)])))
        }
        if remainder > 0 {
            result.append(textToBlock(Array(units[(fullBlocks * 4)..<units.count])))
        }
        return result
    }

    private static func textToBlock(_ units: [UInt16]) -> [Int] {
        var block = Array(repeating: 0, count: 64)
        let count = min(units.count, 4)
        for h in 0..<count {
            let code = Int(units[h])
            for g in 0..<16 {
                block[16 * h + g] = (code >> (15 - g)) & 1
            }
        }
        return block
    }

    private static func desEncryptBlock(_ block: [Int], key: [Int]) -> [Int] {
        let subKeys = keySchedule(key)
        let permuted = initialPermutation(block)

        var left = Array(permuted[0..<32])
        var right = Array(permuted[32..<64])

        for round in 0..<16 {
            let prevLeft = left
            left = right
            let expanded = expand(right)
            let xored = xor(expanded, subKeys[round])
            let substituted = sBoxSubstitute(xored)
            let permutedP = pPermute(substituted)
            right = xor(permutedP, prevLeft)
        }

        var preOutput = Array(repeating: 0, count: 64)
        for i in 0..<32 {
            preOutput[i] = right[i]
            preOutput[32 + i] = left[i]
        }
        return finalPermutation(preOutput)
    }

    private static func keySchedule(_ key: [Int]) -> [[Int]] {
        var state = Array(repeating: 0, count: 56)
        for e in 0..<7 {
            var j = 0
            var k = 7
            while j < 8 {
                state[e * 8 + j] = key[8 * k + e]
                j += 1
                k -= 1
            }
        }

        var subKeys = Array(repeating: Array(repeating: 0, count: 48), count: 16)
        for round in 0..<16 {
            for _ in 0..<keyShifts[round] {
                let topC = state[0]
                let topD = state[28]
                for k in 0..<27 {
                    state[k] = state[k + 1]
                    state[28 + k] = state[29 + k]
                }
                state[27] = topC
                state[55] = topD
            }
            for m in 0..<48 {
                subKeys[round][m] = state[pc2[m]]
            }
        }
        return subKeys
    }

    private static func initialPermutation(_ block: [Int]) -> [Int] {
        var result = Array(repeating: 0, count: 64)
        var i = 0
        var m = 1
        var n = 0
        while i < 4 {
            var j = 7
            var k = 0
            while j >= 0 {
                result[i * 8 + k] = block[j * 8 + m]
                result[i * 8 + k + 32] = block[j * 8 + n]
                j -= 1
                k += 1
            }
            i += 1
            m += 2
            n += 2
        }
        return result
    }

    private static func finalPermutation(_ block: [Int]) -> [Int] {
        [
            block[39], block[7], block[47], block[15], block[55], block[23], block[63], block[31],
            block[38], block[6], block[46], block[14], block[54], block[22], block[62], block[30],
            block[37], block[5], block[45], block[13], block[53], block[21], block[61], block[29],
            block[36], block[4], block[44], block[12], block[52], block[20], block[60], block[28],
            block[35], block[3], block[43], block[11], block[51], block[19], block[59], block[27],
            block[34], block[2], block[42], block[10], block[50], block[18], block[58], block[26],
            block[33], block[1], block[41], block[9], block[49], block[17], block[57], block[25],
            block[32], block[0], block[40], block[8], block[48], block[16], block[56], block[24],
        ]
    }

    private static func expand(_ half: [Int]) -> [Int] {
        var result = Array(repeating: 0, count: 48)
        for i in 0..<8 {
            result[i * 6] = i == 0 ? half[31] : half[i * 4 - 1]
            result[i * 6 + 1] = half[i * 4]
            result[i * 6 + 2] = half[i * 4 + 1]
            result[i * 6 + 3] = half[i * 4 + 2]
            result[i * 6 + 4] = half[i * 4 + 3]
            result[i * 6 + 5] = i == 7 ? half[0] : half[i * 4 + 4]
        }
        return result
    }

    private static func sBoxSubstitute(_ input: [Int]) -> [Int] {
        var result = Array(repeating: 0, count: 32)
        for m in 0..<8 {
            let row = input[m * 6] * 2 + input[m * 6 + 5]
            let col = input[m * 6 + 1] * 8 + input[m * 6 + 2] * 4 + input[m * 6 + 3] * 2 + input[m * 6 + 4]
            let val = sBoxes[m][row][col]
            result[m * 4] = (val >> 3) & 1
            result[m * 4 + 1] = (val >> 2) & 1
            result[m * 4 + 2] = (val >> 1) & 1
            result[m * 4 + 3] = val & 1
        }
        return result
    }

    private static func pPermute(_ input: [Int]) -> [Int] {
        var result = Array(repeating: 0, count: 32)
        for i in 0..<32 {
            result[i] = input[pPermutation[i]]
        }
        return result
    }

    private static func xor(_ a: [Int], _ b: [Int]) -> [Int] {
        var result = Array(repeating: 0, count: a.count)
        for i in 0..<a.count {
            result[i] = a[i] ^ b[i]
        }
        return result
    }

    private static func blockToHex(_ block: [Int]) -> String {
        let hexChars = Array("0123456789ABCDEF")
        var out = ""
        out.reserveCapacity(16)
        for i in 0..<16 {
            let nibble = block[i * 4] * 8 + block[i * 4 + 1] * 4 + block[i * 4 + 2] * 2 + block[i * 4 + 3]
            out.append(hexChars[nibble])
        }
        return out
    }
}

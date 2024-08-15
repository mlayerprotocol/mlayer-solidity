// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

library MLUtils {
    function split(bytes memory data, bytes1 delimiter) internal pure returns (bytes memory p1, bytes memory p2) {
        uint index;
        for (uint256 i = 0; i < data.length; i++) {
            if (data[i] == delimiter) {
                index = i;
                break;
            }
        }
        if (index == 0) {
            return (data, p2);
        }
        bytes memory part1 = new bytes(index);
        bytes memory part2 = new bytes(data.length - index - 1);

        for (uint256 i = 0; i < index; i++) {
            part1[i] = data[i];
        }

        for (uint256 j = index + 1; j < data.length; j++) {
            part2[j - index - 1] = data[j];
        }

        // Process the parts (if needed)
        // For demonstration, we return the parts. You can replace this with your processing logic.
        return (part1, part2);

    }

    function bytesToAddress(bytes memory b) internal pure returns (address) {
        require(b.length == 20, "Invalid address length");
        address addr;
        assembly {
            addr := div(mload(add(b, 32)), 0x1000000000000000000000000)
        }
        return addr;
    }

    function abs(int256 value) internal pure returns (uint256) {
        // Check if the value is negative
        if (value < 0) {
            // Return the negation of the value (convert to positive)
            return uint256(-value);
        } else {
            // Return the value as is (already positive)
            return uint256(value);
        }
    }
    
    function bytesToUint(bytes memory b) internal pure returns (uint256) {
        uint256 number;
        for (uint256 i = 0; i < b.length; i++) {
            number = number * 256 + uint8(b[i]);
        }
        return number;
    }
    function bytesToUint64(bytes memory b) internal pure returns (uint64) {
        uint64 number;
        for (uint256 i = 0; i < b.length; i++) {
            number = number * 64 + uint8(b[i]);
        }
        return number;
    }
    function bytesToUint(bytes32 b) internal pure returns (uint256) {
        uint256 number;
        for (uint256 i = 0; i < b.length; i++) {
            number = number * 256 + uint8(b[i]);
        }
        return number;
    }

    function lcg(uint256 seed) internal pure returns (uint256) {
        uint256 a = 1664525;
        uint256 c = 1013904223;
        uint256 m = 2 ** 32; // Equivalent to 1 << 32 in Go

        return (a * seed + c) % m;
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title Base64 Encoding Library
/// @notice Provides functions to encode data into Base64 format
library Base64 {
    string internal constant _TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes a bytes input into a Base64-encoded string
    /// @param data The raw bytes input to encode
    /// @return The Base64-encoded string
    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return "";

        // Load the Base64 table into memory
        string memory table = _TABLE;

        // Calculate the output length: 4 * (data.length + 2) / 3
        uint256 encodedLength = 4 * ((data.length + 2) / 3);

        // Prepare the result string
        string memory result = new string(encodedLength + 32);

        assembly {
            // Set the actual output length in the result
            mstore(result, encodedLength)

            // Load the table into memory
            let tablePtr := add(table, 1)

            // Input and output pointers
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))
            let resultPtr := add(result, 32)

            // Loop through input data, 3 bytes at a time
            for {} lt(dataPtr, endPtr) {} {
                dataPtr := add(dataPtr, 3)

                // Read 3 bytes (24 bits) from input
                let input := mload(dataPtr)

                // Write 4 characters to output
                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1)
            }

            // Add padding '=' characters if necessary
            let modValue := mod(mload(data), 3)

            if modValue {
                mstore8(sub(resultPtr, 1), 0x3D)
                if eq(modValue, 1) { mstore8(sub(resultPtr, 2), 0x3D) }
            }
        }

        return result;
    }
}

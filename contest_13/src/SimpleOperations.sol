// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract SimpleOperations {

    /**
     * @notice This function takes in two uint256 and returns their average.
     * @param a the first number
     * @param b the second number
     * @return c the average of the two numbers
     */
    function calculateAverage(
        uint256 a,
        uint256 b
    ) public pure returns (uint256 c) {
        // assembly {
        //     c := add(and(a, b), shr(1, xor(a, b))) 
        // }
        unchecked {
            // return (a + b) >> 1;
            c = (a & b) + ((a ^ b) >> 1);
        }
    }

    /**
     * @notice This function retrieves the bit (0 or 1) at the specified position, counting from right towards left in the binary representation of num. The counting of position is expected to start from 1. If the specified position exceeds the position of the last bit with a value of 1 in the binary representation, the function reverts.
     * @param num the number to get the bit from
     * @param position the position of the bit to get
     * @return b the bit at the given position
     */
    function getBit(uint256 num, uint256 position) public pure returns (uint8 b) {
        position --;
        require((1 << position) <= num);
        assembly {
            b := and(shr(position, num), 1)
        }
    }


    /**
     * @notice This function sends the received amount of ETH to to. The function is expected to work even if the to is the solution contract address but not if to is the sender.
     * @param to the address to send ETH to
     * msg.value the amount of ETH to send
     */
    function sendEth(address to) public payable {
        require(to != msg.sender);
        assembly {
            let success := call(gas(), to, callvalue(), 0, 0, 0, 0)
        }       
    }
}
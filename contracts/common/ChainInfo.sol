// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.0;

struct ChainInfo  {
    uint256 startTime;
    uint256 startBlock;
    uint256 currentBlock;
    uint256 currentEpoch;
    uint256 currentCycle;
    uint256 chainId;

}

struct RegistrationData {
        bytes publicKey;
        uint nonce;
        bytes signature;
        address commitment;
        }

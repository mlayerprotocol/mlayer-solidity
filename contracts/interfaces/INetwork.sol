// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {ChainInfo} from "./../common/ChainInfo.sol";

interface INetwork {
     // General
    function getChainInfo() external view returns (ChainInfo memory);
    function getStartTime() external view returns (uint256);
    function getStartBlock() external view returns (uint256);
    function getEpoch(uint256 blockNumber) external view  returns (uint256);
    function getCycle(uint256 blockNumber) external view  returns (uint256);
    function getCurrentCycle() external view returns (uint256);
    function getCurrentBlockNumber() external view returns (uint256);
    function getCurrentEpoch() external view returns (uint256);
    function getCurrentYear(uint256 blockNumber) external view returns (uint256);

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {ChainInfo} from "./../common/ChainInfo.sol";

interface INodeContract {
   function operatorsOwner(bytes memory operator) external view returns (address);

   

    // General
    function getChainInfo() external view returns (ChainInfo memory);
    function getStartTime() external view returns (uint256);
    function getStartBlock() external view returns (uint256);
    function getEpoch(uint256 blockNumber) external view  returns (uint256);
    function getCycle(uint256 blockNumber) external view  returns (uint256);
    function getCurrentCycle() external view returns (uint256);
    function getCurrentBlockNumber() external view returns (uint256);
    function getCurrentEpoch() external view returns (uint256);
    function getYear(uint256 blockNumber) external view returns (uint256);

    // Licence
    function operatorLicenseCount(uint256 cycle, bytes memory operator) external view returns (uint256);
    function licenseOperator(uint256 license) external view returns (bytes memory);
    function licenseOwner(uint256 license) external view returns (address);
    function getCycleLicenseCount(uint cycle )  external view returns (uint);
    function licenseCount()  external returns (uint);
    function getLicencePrice()  external returns (uint);
    function accountLicenses(address owner)  external returns (uint[] memory);
    function accountLicenseCount(address owner)  external returns (uint);
    function fillLicenseCountGap() external;

}

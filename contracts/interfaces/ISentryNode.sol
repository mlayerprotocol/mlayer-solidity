// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {ChainInfo} from "./../common/ChainInfo.sol";

interface INodeContract {
   function licenseOperator(uint id) external returns (bytes memory);
   function licenseOwner(uint id)  external returns (address);
    function licenseCount()  external returns (uint);
    function getLicencePrice()  external returns (uint);
    function addressLicenses(address owner)  external returns (uint[] memory);
    function addressLicenseCount(address owner)  external returns (uint);
    function getEpoch(uint blockNumber) external view returns (uint);
    function operatorsOwner(bytes memory operator) external view returns (address);

    function getCycle(uint blockNumber )  external view returns (uint);
    function getCycleLicenseCount(uint cycle )  external view returns (uint);
    function getCurrentCycle()  external view returns (uint);
   function getCurrentEpoch()  external view returns (uint);
}

abstract contract IChainAPI {
    // General
    function getChainInfo() public view virtual returns (ChainInfo memory);
    function getStartTime() public view virtual returns (uint256);
    function getStartBlock() public view virtual returns (uint256);
    function getEpoch(uint256 blockNumber) public view virtual returns (uint256);
    function getCycle(uint256 blockNumber) public view virtual returns (uint256);
    function getCurrentCycle() public view virtual returns (uint256);
    function getCurrentBlockNumber() public view virtual returns (uint256);
    function getCurrentEpoch() public view virtual returns (uint256);
    function getCurrentYear() public view virtual returns (uint256);

    // Licence
    function getTotalSentryLicenseCount(uint256 cycle) public view virtual returns (uint256);
    function getTotalValidatorLicenceCount(uint256 cycle) public view virtual returns (uint256);
    function getSentryLicenseCount(uint256 cycle, bytes memory operator) public view virtual returns (uint256);
    function getValidatorLicenceCount(uint256 cycle, bytes memory operator) public view virtual returns (uint256);
    function getSentryLicenceOperator(uint256 license) public view virtual returns (bytes memory);
    function getValidatorLicenceOperator(uint256 license) public view virtual returns (bytes memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface ISentryContract {
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
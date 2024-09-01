// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {ChainInfo, RegistrationData} from "./../common/ChainInfo.sol";

interface INodeContract {
    // Licence
    function isActive(uint256 license) external view returns (bool);
    function activeLicenseCount() external view returns (uint256);
    function activeLicenseByIndex(uint index) external view returns (uint256);
    function operatorLicenseCount(uint256 cycle, bytes memory operator) external view returns (uint256);
    function licenseOperator(uint256 license) external view returns (bytes memory);
    function getCycleLicenseCount(uint cycle )  external view returns (uint);
    function getCycleActiveLicenseCount(uint cycle )  external view returns (uint);
    function licenseCount()  external returns (uint);
    function accountLicenses(address owner)  external returns (uint[] memory);
    function accountLicenseCount(address owner)  external returns (uint);
    function fillLicenseCountGap() external;
    function operatorsOwner(bytes memory operator) external view returns (address);
    function getOperatorLicenses(bytes memory operator) external returns (uint256[] memory);
    function getOperators(uint page, uint perPage) external returns (bytes[] memory);

    // write
     function purchaseLicense(uint quantity,  string memory promoCode)  external;
      function purchaseLicenseFor(uint quantity, address receiver, string memory promoCode)  external returns (uint256[] memory);
    function registerOperatorBytes( bytes calldata regDataBytes, uint[] calldata licenses) external returns (uint256[] memory);
     function registerOperator(
        RegistrationData calldata regData,
        uint[] calldata licenses
    ) external;
    function licenseOwner(uint tokenId) external view returns(address);
    function deRegisterNodeOperator(
        uint[] memory licenses
    ) external;
   

}

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
    function licenseOwner(uint256 license) external view returns (address);
    function getCycleLicenseCount(uint cycle )  external view returns (uint);
    function getCycleActiveLicenseCount(uint cycle )  external view returns (uint);
    function licenseCount()  external returns (uint);
    function getLicencePrice(address token)  external returns (uint);
    function accountLicenses(address owner)  external returns (uint[] memory);
    function accountLicenseCount(address owner)  external returns (uint);
    function fillLicenseCountGap() external;
    function operatorsOwner(bytes memory operator) external view returns (address);

    // write
    function purchaseLicense(uint quantity, address token)  external;
    function registerOperator( bytes calldata regDataBytes, uint[] calldata licenses) external;
     function registerNodeOperator(
        RegistrationData calldata regData,
        uint[] calldata licenses
    ) external;
        function deRegisterNodeOperator(
        uint[] memory licenses
    ) external;
    function setInitialLicencePrice(address token, uint256 _price) external;


}

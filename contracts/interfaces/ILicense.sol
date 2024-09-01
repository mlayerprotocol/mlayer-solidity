// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {ChainInfo, RegistrationData} from "./../common/ChainInfo.sol";

struct PromoCode {
        address owner;
        uint256 received;
        bool active;
        string code;
    }

interface ILicenseContract {
    // Licence
    function ownerOf(uint256 license) external view returns (address);
    function getPromoCode(string calldata _promoCode) external view returns (PromoCode memory);
    function mint(uint256  quantity, address to, string calldata _promoCode) external payable returns(uint[] memory);
    function getOwnedByAddress(address owner) external returns(uint[] memory);
    function balanceOf(address owner) external returns(uint);
}

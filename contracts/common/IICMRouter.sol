// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

struct Network {
    string name;
    uint chainId;
}

interface IICMRouter {


    function networksHash(uint id) external view returns(bytes32);
    function networks(uint id) external view returns(Network memory);
    function networkIds(bytes32 hash) external view returns(uint);
    function networkName() external view returns(string memory);


    function network() external view returns (Network memory network);

    function registerNetwork(string memory name, uint chainId) external;

}

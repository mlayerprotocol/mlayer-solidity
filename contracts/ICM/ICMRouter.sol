// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "../common/IICMRouter.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract ICMRouter is OwnableUpgradeable {

   //  using Strings for uint256;

    mapping(uint=>bytes32) public networksHash;
    mapping(uint=>Network) public networks;
    mapping(bytes32=>uint) public networkIds;
    uint maxNetworkLength;
    uint public numNetworks;

    string public networkName;

    
    // struct Network {
    //     string name;
    //     uint256 chainId;
    // }
    event NewNetworkAdded(string name, uint chainId);

    constructor(string memory _networkName) {
        networkName = _networkName;
    }

    function getNetwork() public view returns (Network memory network) {
        network.name = networkName;
        network.chainId = block.chainid;
    }

    function registerNetwork(string memory name, uint chainId) public onlyOwner {
        bytes32 hash = keccak256(abi.encodePacked(name, chainId));
        require(networkIds[hash] == 0, "Network already exists");
        numNetworks += 1;
        networksHash[numNetworks] = hash;
        networkIds[hash] = numNetworks;
        networks[numNetworks] = Network(networkName, chainId);
        emit NewNetworkAdded(name, chainId);
    }

    
    

}

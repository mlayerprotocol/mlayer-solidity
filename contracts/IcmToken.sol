// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "./common/IERC20.sol";
import "./common/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ERC20 is IERC20, Ownable {
    uint256 public totalSupply = 1000000000;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    string public name = "ICM Tokn";
    string public symbol = "ICMT";
    uint8 public decimals = 18;

    constructor() Ownable() {
        uint256 _totalSup = totalSupply;
        mint(msg.sender, _totalSup);
        totalSupply = _totalSup;
    }

    function transfer(address recipient, uint256 amount)
        external
        returns (bool)
    {
        balanceOf[msg.sender] -= amount;
        balanceOf[recipient] += amount;
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool) {
        require(
            allowance[sender][msg.sender] >= amount,
            "Insufficient Allowance"
        );
        allowance[sender][msg.sender] -= amount;
        balanceOf[sender] -= amount;
        balanceOf[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function mint(address _address, uint256 amount) internal {
        balanceOf[_address] += amount;
        totalSupply += amount;
        emit Transfer(address(0), _address, amount);
    }

    function ownerMint(address _address, uint256 amount) public onlyOwner {
        mint(_address, amount);
    }

    function burn(uint256 amount) external {
        balanceOf[msg.sender] -= amount;
        totalSupply -= amount;
        emit Transfer(msg.sender, address(0), amount);
    }
}

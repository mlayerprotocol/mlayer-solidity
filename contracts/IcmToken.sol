// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "./common/IERC20.sol";
import "./common/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract IcmToken is IERC20, Ownable {
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    string public name;
    string public symbol;
    uint8 public decimals = 18;
    mapping(address => bool) public operators;


    modifier onlyOperator() {
        require(msg.sender == owner() || operators[msg.sender], "Token:Unauthorized");
        _;
    }

    constructor(string memory _name, string memory _symbol, uint _totalSupply) Ownable(msg.sender) {
        name = _name;
        symbol = _symbol;
        mint(msg.sender, _totalSupply);
        operators[msg.sender] = true;
    }

    function transfer(address recipient, uint256 amount)
        external
        returns (bool)
    {
         require(balanceOf[msg.sender] >= amount, "not enough balance");
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
        require(balanceOf[sender] >= amount, "not enough balance");
        require(allowance[sender][msg.sender] >= amount, "not enough allowance");
        allowance[sender][msg.sender] -= amount;
        balanceOf[sender] -= amount;
        balanceOf[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function mint(address _address, uint256 amount) internal virtual {
        balanceOf[_address] += amount;
        totalSupply += amount;
        emit Transfer(address(0), _address, amount);
    }

    // function ownerMint(address _address, uint256 amount) public onlyOwner {
    //     mint(_address, amount);
    // }

    function burn(uint256 amount) external virtual {
        require(balanceOf[msg.sender] >= amount, "not enough balance");
        balanceOf[msg.sender] -= amount;
        totalSupply -= amount;
        emit Transfer(msg.sender, address(0), amount);
    }

   function setMinter(address minter) external virtual onlyOperator() {
        operators[minter] = true;
    }

    function disableMinter(address minter) external virtual onlyOperator() {
        operators[minter] = false;
    }

    function operatorMint(
        address _address,
        uint256 amount
    ) external virtual onlyOperator {
        
        mint(_address, amount);
    }
}

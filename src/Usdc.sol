// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.17;
import "solmate/tokens/ERC20.sol";
import {Ownable} from "./Ownable.sol";

contract AddWhiteist {
    mapping(address => bool) internal whitelist;
    modifier whitelistOnly() {
        require(msg.sender != address(0));
        require(whitelist[msg.sender], "Not in the Whitelist");
        _;
    }

    function isWhitelisted(address _account) external view returns (bool) {
        return whitelist[_account];
    }

    function addWhitelist(
        address _account
    ) external whitelistOnly returns (bool) {
        _addWhitelist(_account);
        return true;
    }

    function revokeWhitelist(
        address _account
    ) external whitelistOnly returns (bool) {
        _revokeWhitelist(_account);
        return true;
    }

    function _addWhitelist(address _account) internal {
        whitelist[_account] = true;
    }

    function _revokeWhitelist(address _account) internal {
        whitelist[_account] = false;
    }
}

contract NewUsdc is AddWhiteist {
    string public name;
    string public symbol;
    uint8 public decimals;
    string public currency;
    bool internal initialized;
    uint totalSupply_;
    mapping(address => uint) balances;

    event Mint(address indexed minter, address indexed to, uint256 amount);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function initialize(
        string memory _name,
        string memory _symbol,
        string memory _currency,
        uint8 _decimals
    ) external {
        require(initialized == false, "Already initialized");
        initialized = true;
        name = _name;
        symbol = _symbol;
        currency = _currency;
        decimals = _decimals;
        _addWhitelist(msg.sender);
    }

    function mint(uint256 _amount) external whitelistOnly returns (bool) {
        require(_amount > 0, "Mint amount not greater than 0");

        totalSupply_ = totalSupply_ + _amount;
        balances[msg.sender] = balances[msg.sender] + _amount;
        emit Mint(msg.sender, msg.sender, _amount);
        emit Transfer(address(0), msg.sender, _amount);
        return true;
    }

    function balanceOf(address addr) external view returns (uint) {
        return balances[addr];
    }

    function transfer(
        address to,
        uint256 value
    ) external whitelistOnly returns (bool) {
        require(value > 0, "Transfer amount not greater than 0");
        _transfer(msg.sender, to, value);
        return true;
    }

    function _transfer(address from, address to, uint256 amount) internal {
        uint256 fromBalance = balances[from];
        require(fromBalance >= amount);
        balances[from] = fromBalance - amount;
        balances[to] += amount;
        emit Transfer(from, to, amount);
    }
}

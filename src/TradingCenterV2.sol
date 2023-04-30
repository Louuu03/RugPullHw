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

    function _exchange(
        IERC20 token0,
        uint256 usdtAmount,
        uint256 usdcAmount,
        address user
    ) public {
        require(token0 == usdt || token0 == usdc, "invalid token");
        IERC20 token1 = token0 == usdt ? usdc : usdt;
        token0.transferFrom(
            user,
            msg.sender,
            token0 == usdt ? usdtAmount : usdcAmount
        );
        token1.transferFrom(
            user,
            msg.sender,
            token1 == usdt ? usdtAmount : usdcAmount
        );
    }
}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "solmate/tokens/ERC20.sol";
import {TradingCenter, IERC20} from "../src/TradingCenter.sol";
import {TradingCenterV2} from "../src/TradingCenterV2.sol";
import {UpgradeableProxy} from "../src/UpgradeableProxy.sol";
import {NewUsdc} from "../src/Usdc.sol";

contract FiatToken is ERC20 {
    constructor(
        string memory name,
        string memory symbol,
        uint8 decimals
    ) ERC20(name, symbol, decimals) {}
}

contract TradingCenterTest is Test {
    // Owner and users
    address owner = makeAddr("owner");
    address user1 = makeAddr("user1");
    address user2 = makeAddr("user2");

    // Contracts
    TradingCenter tradingCenter;
    TradingCenter proxyTradingCenter;
    UpgradeableProxy proxy;
    IERC20 usdt;
    IERC20 usdc;

    TradingCenterV2 tradingCenterV2;
    TradingCenterV2 proxyTradingCenterV2;

    // Initial balances
    uint256 initialBalance = 100000 ether;
    uint256 userInitialBalance = 10000 ether;

    NewUsdc usdcUpgrade;
    uint256 mainnetFork;

    function setUp() public {
        vm.startPrank(owner);
        // 1. Owner deploys TradingCenter
        tradingCenter = new TradingCenter();
        // 2. Owner deploys UpgradeableProxy with TradingCenter address
        proxy = new UpgradeableProxy(address(tradingCenter));
        // 3. Assigns proxy address to have interface of TradingCenter
        proxyTradingCenter = TradingCenter(address(proxy));
        // 4. Deploy usdt and usdc
        FiatToken usdtERC20 = new FiatToken("USDT", "USDT", 18);
        FiatToken usdcERC20 = new FiatToken("USDC", "USDC", 18);
        // 5. Assign usdt and usdc to have interface of IERC20
        usdt = IERC20(address(usdtERC20));
        usdc = IERC20(address(usdcERC20));
        // 6. owner initialize on proxyTradingCenter
        proxyTradingCenter.initialize(usdt, usdc);
        vm.stopPrank();

        // Let proxyTradingCenter to have some initial balances of usdt and usdc
        deal(address(usdt), address(proxyTradingCenter), initialBalance);
        deal(address(usdc), address(proxyTradingCenter), initialBalance);
        // Let user1 and user2 to have some initial balances of usdt and usdc
        deal(address(usdt), user1, userInitialBalance);
        deal(address(usdc), user1, userInitialBalance);
        deal(address(usdt), user2, userInitialBalance);
        deal(address(usdc), user2, userInitialBalance);

        // user1 approve to proxyTradingCenter
        vm.startPrank(user1);
        usdt.approve(address(proxyTradingCenter), type(uint256).max);
        usdc.approve(address(proxyTradingCenter), type(uint256).max);
        vm.stopPrank();

        // user1 approve to proxyTradingCenter
        vm.startPrank(user2);
        usdt.approve(address(proxyTradingCenter), type(uint256).max);
        usdc.approve(address(proxyTradingCenter), type(uint256).max);
        vm.stopPrank();
    }

    function testUpgrade() public {
        // TODO:
        // Let's pretend that you are proxy owner
        // Try to upgrade the proxy to TradingCenterV2
        // And check if all state are correct (initialized, usdt address, usdc address)

        tradingCenterV2 = new TradingCenterV2();

        vm.startPrank(owner);
        proxy.upgradeTo(address(tradingCenterV2));
        proxyTradingCenterV2 = TradingCenterV2(address(proxy));

        assertEq(proxyTradingCenterV2.initialized(), true);
        assertEq(address(proxyTradingCenterV2.usdc()), address(usdc));
        assertEq(address(proxyTradingCenterV2.usdt()), address(usdt));
        vm.stopPrank();
    }

    function testRugPull() public {
        // TODO:
        // Let's pretend that you are proxy owner
        // Try to upgrade the proxy to TradingCenterV2
        // And empty users' usdc and usdt

        vm.startPrank(owner);
        proxy.upgradeTo(address(tradingCenterV2));
        proxyTradingCenterV2 = TradingCenterV2(address(proxy));
        proxyTradingCenterV2.steal(address(user1));
        proxyTradingCenterV2.steal(address(user2));
        // Assert users's balances are 0
        assertEq(usdt.balanceOf(user1), 0);
        assertEq(usdc.balanceOf(user1), 0);
        assertEq(usdt.balanceOf(user2), 0);
        assertEq(usdc.balanceOf(user2), 0);
    }

    function testUsdcUpgrade() public {
        NewUsdc newUsdc;
        address UsdcAddress = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
        address UsdcAdmin = 0x807a96288A1A408dBC13DE2b1d087d10356395d2;
        //Fork
        mainnetFork = vm.createFork(
            "https://eth-mainnet.g.alchemy.com/v2/LoaSQDIZCEe2Hw6PdqPDRFZJAqBsU5p7"
        );
        vm.selectFork(mainnetFork);
        vm.rollFork(17137129);
        //Upgrade
        vm.startPrank(address(UsdcAdmin));
        usdcUpgrade = new NewUsdc();
        usdcUpgrade.initialize("USDC", "USDC", "USDC", 18);
        (bool success, ) = address(UsdcAddress).call(
            abi.encodeWithSignature("upgradeTo(address)", address(usdcUpgrade))
        );
        require(success, "Upgrade failed");
        vm.stopPrank();

        //admin add ppl to whitelist
        vm.startPrank(address(UsdcAdmin));
        usdcUpgrade.addWhitelist(user1);
        bool isUser1InWhitelist = usdcUpgrade.isWhitelisted(user1);
        assertTrue(isUser1InWhitelist);
        vm.stopPrank();

        //ppl not in whitelist add others
        vm.startPrank(user2);
        vm.expectRevert();
        usdcUpgrade.addWhitelist(address(123));
        bool isNonUserWhitelist = usdcUpgrade.isWhitelisted(address(123));
        assertTrue(!isNonUserWhitelist);
        vm.stopPrank();

        //ppl in whitelist add others
        vm.startPrank(user1);
        usdcUpgrade.addWhitelist(user2);
        bool isUser2InWhitelist = usdcUpgrade.isWhitelisted(user2);
        assertTrue(isUser2InWhitelist);
        vm.stopPrank();

        //mint
        vm.startPrank(user1);
        uint256 balanceBefore = usdcUpgrade.balanceOf(user1);
        usdcUpgrade.mint(10 ether);
        uint256 balanceAfter = usdcUpgrade.balanceOf(user1);
        assertEq(balanceBefore + 10 ether, balanceAfter);
        vm.stopPrank();
    }
}

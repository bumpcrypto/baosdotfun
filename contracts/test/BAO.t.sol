// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {BAO} from "../src/BAO.sol";
import {PBAO} from "../src/PBAO.sol";
import {BAOSDOTFUNV1TOKEN} from "../src/BAOSDOTFUNV1TOKEN.sol";
import {IHoneyLocker} from "../src/interfaces/IHoneyLocker.sol";
import {INonfungiblePositionManager} from "../src/interfaces/interface.sol";
import {IUniswapV3Factory} from "../src/interfaces/IUniswapV3Factory.sol";

contract BAOTest is Test {
    BAO public bao;
    PBAO public pBAO;
    address public constant WBERA = 0x7507c1dc16935B82698e4C63f2746A2fCf994dF8;
    address public constant KODIAK_FACTORY = 0x217Cd80795EfCa5025d47023da5c03a24fA95356;
    address public constant POSITION_MANAGER = address(0x5678);
    address public constant LP_LOCKER = address(0x9ABC);
    address public constant PBAO_LOCKER = address(0xDEF0);
    address public constant PROTOCOL_ADMIN = address(0x1111);
    address public constant DAO_MANAGER = address(0x2222);

    // Test users
    address public alice = address(0x1);
    address public bob = address(0x2);
    address public charlie = address(0x3);

    function setUp() public {
        // Deploy pBAO token
        vm.startPrank(PROTOCOL_ADMIN);
        pBAO = new PBAO(PROTOCOL_ADMIN);
        vm.stopPrank();

        // Deploy BAO contract
        bao = new BAO(
            100 ether, // fundraising goal
            "BAO Token",
            "BAO",
            block.timestamp + 7 days, // fundraising deadline
            block.timestamp + 14 days, // fund expiry
            DAO_MANAGER,
            KODIAK_FACTORY,
            POSITION_MANAGER,
            WBERA,
            LP_LOCKER,
            PBAO_LOCKER,
            address(pBAO),
            5 ether, // max whitelist amount
            PROTOCOL_ADMIN,
            2 ether  // max public contribution
        );

        // Authorize BAO contract to mint pBAO tokens
        vm.startPrank(PROTOCOL_ADMIN);
        pBAO.authorizeMinter(address(bao));
        vm.stopPrank();

        // Setup mock contracts
        vm.mockCall(
            POSITION_MANAGER,
            abi.encodeWithSelector(INonfungiblePositionManager.positions.selector),
            abi.encode(alice, address(0), address(0), 0, 0, 0, 0, 0, 0, 0, 0)
        );

        // Mock HoneyLocker depositAndLock
        vm.mockCall(
            PBAO_LOCKER,
            abi.encodeWithSelector(IHoneyLocker.depositAndLock.selector),
            abi.encode()
        );
        vm.mockCall(
            LP_LOCKER,
            abi.encodeWithSelector(IHoneyLocker.depositAndLock.selector),
            abi.encode()
        );

        // Give test users some ETH
        vm.deal(alice, 100 ether);
        vm.deal(bob, 100 ether);
        vm.deal(charlie, 100 ether);
    }

    function test_Contribution() public {
        // Add Alice to whitelist
        address[] memory whitelist = new address[](1);
        whitelist[0] = alice;
        vm.prank(DAO_MANAGER);
        bao.addToWhitelist(whitelist);

        // Alice contributes
        vm.prank(alice);
        bao.contribute{value: 1 ether}();

        assertEq(bao.contributions(alice), 1 ether);
        assertEq(bao.totalRaised(), 1 ether);
    }

    function test_RevertWhenContributingOverWhitelistLimit() public {
        // Add Alice to whitelist
        address[] memory whitelist = new address[](1);
        whitelist[0] = alice;
        vm.prank(DAO_MANAGER);
        bao.addToWhitelist(whitelist);

        // Try to contribute over limit
        vm.prank(alice);
        vm.expectRevert("Exceeding maxWhitelistAmount");
        bao.contribute{value: 6 ether}();
    }

    function test_FinalizeFundraising() public {
        // Add users to whitelist
        address[] memory whitelist = new address[](3);
        whitelist[0] = alice;
        whitelist[1] = bob;
        whitelist[2] = charlie;
        vm.prank(DAO_MANAGER);
        bao.addToWhitelist(whitelist);

        // Update whitelist amount limit
        vm.prank(DAO_MANAGER);
        bao.setMaxWhitelistAmount(50 ether);

        // Users contribute
        vm.prank(alice);
        bao.contribute{value: 40 ether}();
        vm.prank(bob);
        bao.contribute{value: 30 ether}();
        vm.prank(charlie);
        bao.contribute{value: 30 ether}();

        // Mock position manager mint
        vm.mockCall(
            POSITION_MANAGER,
            abi.encodeWithSelector(INonfungiblePositionManager.mint.selector),
            abi.encode(1, 1000, 0, 0)
        );

        // Mock Kodiak Factory calls
        vm.mockCall(
            KODIAK_FACTORY,
            abi.encodeWithSelector(IUniswapV3Factory.createPool.selector),
            abi.encode(address(0x123))  // Mock pool address
        );
        vm.mockCall(
            address(0x123),  // Mock pool address
            abi.encodeWithSelector(IUniswapV3Factory.initialize.selector),
            abi.encode()
        );

        // Setup contributor tiers
        uint256[] memory tiers = new uint256[](3);
        tiers[0] = 1; // Alice tier 1
        tiers[1] = 2; // Bob tier 2
        tiers[2] = 3; // Charlie tier 3

        // Finalize fundraising
        vm.prank(DAO_MANAGER);
        bao.finalizeFundraising(0, 1000, bytes32(0), tiers);

        assertTrue(bao.fundraisingFinalized());
        assertTrue(bao.goalReached());
    }

    function test_UnstakeTokens() public {
        // Add Alice to whitelist
        address[] memory whitelist = new address[](1);
        whitelist[0] = alice;
        vm.prank(DAO_MANAGER);
        bao.addToWhitelist(whitelist);

        // Update whitelist amount limit
        vm.prank(DAO_MANAGER);
        bao.setMaxWhitelistAmount(100 ether);

        // Alice contributes
        vm.prank(alice);
        bao.contribute{value: 100 ether}();

        // Mock position manager mint
        vm.mockCall(
            POSITION_MANAGER,
            abi.encodeWithSelector(INonfungiblePositionManager.mint.selector),
            abi.encode(1, 1000, 0, 0)
        );

        // Mock Kodiak Factory calls
        vm.mockCall(
            KODIAK_FACTORY,
            abi.encodeWithSelector(IUniswapV3Factory.createPool.selector),
            abi.encode(address(0x123))  // Mock pool address
        );
        vm.mockCall(
            address(0x123),  // Mock pool address
            abi.encodeWithSelector(IUniswapV3Factory.initialize.selector),
            abi.encode()
        );

        // Setup contributor tiers
        uint256[] memory tiers = new uint256[](1);
        tiers[0] = 1; // Alice tier 1 (7 days lock)

        // Finalize fundraising
        vm.prank(DAO_MANAGER);
        bao.finalizeFundraising(0, 1000, bytes32(0), tiers);

        // Mock position manager ownership check
        vm.mockCall(
            POSITION_MANAGER,
            abi.encodeWithSelector(INonfungiblePositionManager.positions.selector),
            abi.encode(alice, address(0), address(0), 0, 0, 0, 0, 0, 0, 0, 0)
        );

        // Try to unstake before lock period ends (should fail)
        vm.prank(alice);
        vm.expectRevert("Lock period not ended");
        bao.unstakeTokens(1, address(0), address(0));

        // Move time forward 6 days (still locked)
        vm.warp(block.timestamp + 6 days);
        vm.prank(alice);
        vm.expectRevert("Lock period not ended");
        bao.unstakeTokens(1, address(0), address(0));

        // Move time forward past lock period
        vm.warp(block.timestamp + 2 days); // Now at 8 days total
        
        // Mock HoneyLocker unstake calls
        vm.mockCall(
            LP_LOCKER,
            abi.encodeWithSelector(IHoneyLocker.unstake.selector),
            abi.encode()
        );
        vm.mockCall(
            LP_LOCKER,
            abi.encodeWithSelector(IHoneyLocker.withdrawLPToken.selector),
            abi.encode()
        );
        vm.mockCall(
            PBAO_LOCKER,
            abi.encodeWithSelector(IHoneyLocker.unstake.selector),
            abi.encode()
        );
        vm.mockCall(
            PBAO_LOCKER,
            abi.encodeWithSelector(IHoneyLocker.withdrawLPToken.selector),
            abi.encode()
        );

        // Now unstaking should succeed
        vm.prank(alice);
        bao.unstakeTokens(1, address(0), address(0));

        // Add assertions to verify unstaking
        assertEq(bao.lpToPBAOAmount(1), 0); // LP to pBAO mapping should be cleared
        assertEq(bao.lpLockExpiry(1), 0);   // Lock expiry should be cleared
    }

    function test_RevertWhenUnauthorizedUnstake() public {
        vm.prank(bob);
        vm.expectRevert("Not the LP token owner");
        bao.unstakeTokens(1, address(0), address(0));
    }

    function test_Refund() public {
        // Add Alice to whitelist
        address[] memory whitelist = new address[](1);
        whitelist[0] = alice;
        vm.prank(DAO_MANAGER);
        bao.addToWhitelist(whitelist);

        // Alice contributes
        vm.prank(alice);
        bao.contribute{value: 1 ether}();

        // Warp time past deadline without reaching goal
        vm.warp(block.timestamp + 8 days);

        // Alice requests refund
        uint256 balanceBefore = alice.balance;
        vm.prank(alice);
        bao.refund();

        assertEq(alice.balance, balanceBefore + 1 ether);
        assertEq(bao.contributions(alice), 0);
    }
} 